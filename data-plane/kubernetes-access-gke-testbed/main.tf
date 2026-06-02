terraform {
  required_version = ">= 1.6.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.10"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  default_labels = {
    teleport-creator = replace(split("@", var.user)[0], ".", "-")
    env              = var.env
    managed-by       = "terraform"
  }
}

data "google_client_config" "default" {}

# The join token CRD lives on the Teleport control plane cluster
provider "kubectl" {
  alias                  = "control_plane"
  host                   = var.control_plane_cluster_endpoint
  cluster_ca_certificate = base64decode(var.control_plane_cluster_ca_certificate)
  token                  = var.control_plane_cluster_token
  load_config_file       = false
}

# The kube-agent Helm chart is deployed on the testbed cluster
provider "helm" {
  kubernetes {
    host                   = "https://${google_container_cluster.testbed.endpoint}"
    cluster_ca_certificate = base64decode(google_container_cluster.testbed.master_auth[0].cluster_ca_certificate)
    token                  = data.google_client_config.default.access_token
  }
}

provider "kubernetes" {
  host                   = "https://${google_container_cluster.testbed.endpoint}"
  cluster_ca_certificate = base64decode(google_container_cluster.testbed.master_auth[0].cluster_ca_certificate)
  token                  = data.google_client_config.default.access_token
}

resource "google_service_account" "testbed_nodes" {
  account_id   = "${var.testbed_name}-nodes"
  display_name = "GKE node SA for testbed ${var.testbed_name}"
  project      = var.project_id
}

resource "google_project_iam_member" "testbed_log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.testbed_nodes.email}"
}

resource "google_project_iam_member" "testbed_metric_writer" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.testbed_nodes.email}"
}

# Passthrough internal LBs are only reachable within the same VPC — not from
# peered VPCs or VPN tunnels. The testbed shares the control plane VPC to
# simulate on-prem reaching the ILB via Cloud Interconnect.
data "google_compute_network" "control_plane" {
  name    = var.control_plane_network_name
  project = var.project_id
}

resource "google_compute_subnetwork" "testbed" {
  name          = "${var.testbed_name}-subnet"
  region        = var.region
  network       = data.google_compute_network.control_plane.id
  ip_cidr_range = "10.200.1.0/24"
  project       = var.project_id

  secondary_ip_range {
    range_name    = "${var.testbed_name}-pods"
    ip_cidr_range = "10.201.0.0/16"
  }

  secondary_ip_range {
    range_name    = "${var.testbed_name}-services"
    ip_cidr_range = "10.202.0.0/20"
  }
}

resource "google_container_cluster" "testbed" {
  name     = "${var.testbed_name}-cluster"
  location = var.region
  project  = var.project_id

  deletion_protection = false

  network    = data.google_compute_network.control_plane.id
  subnetwork = google_compute_subnetwork.testbed.id

  remove_default_node_pool = true
  initial_node_count       = 1

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  ip_allocation_policy {
    cluster_secondary_range_name  = "${var.testbed_name}-pods"
    services_secondary_range_name = "${var.testbed_name}-services"
  }

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = "10.203.0.0/28"
  }

  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = "0.0.0.0/0"
      display_name = "all"
    }
  }
}

resource "google_container_node_pool" "testbed" {
  name     = "${var.testbed_name}-pool"
  cluster  = google_container_cluster.testbed.id
  location = var.region
  project  = var.project_id

  node_count = var.node_count

  node_config {
    machine_type    = var.machine_type
    service_account = google_service_account.testbed_nodes.email
    oauth_scopes    = ["https://www.googleapis.com/auth/cloud-platform"]

    workload_metadata_config {
      mode = "GKE_METADATA"
    }
  }
}

# Workload Identity binding so the kube-agent pod can obtain a GCE identity token.
# GKE_METADATA mode blocks the identity endpoint unless the KSA is bound to a GSA.
resource "google_service_account_iam_member" "testbed_workload_identity" {
  service_account_id = google_service_account.testbed_nodes.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[teleport-agent/teleport-kube-agent]"
}

# Join token lives on the control plane cluster, not the testbed cluster.
resource "kubectl_manifest" "join_token" {
  provider   = kubectl.control_plane
  apply_only = true
  yaml_body  = yamlencode({
    apiVersion = "resources.teleport.dev/v2"
    kind       = "TeleportProvisionToken"
    metadata = {
      name      = "${var.testbed_name}-kube-agent"
      namespace = var.teleport_namespace
    }
    spec = {
      roles       = ["Kube"]
      join_method = "gcp"
      gcp = {
        allow = [
          {
            project_ids      = [var.project_id]
            service_accounts = [google_service_account.testbed_nodes.email]
          }
        ]
      }
    }
  })
}

resource "time_sleep" "wait_for_testbed" {
  depends_on      = [google_container_node_pool.testbed]
  create_duration = "60s"
}

resource "helm_release" "kube_agent" {
  name             = "teleport-kube-agent"
  namespace        = "teleport-agent"
  repository       = "https://charts.releases.teleport.dev"
  chart            = "teleport-kube-agent"
  version          = var.teleport_version
  create_namespace = true
  wait             = true
  timeout          = 300

  values = [
    jsonencode({
      roles = "kube"
      joinParams = {
        method    = "gcp"
        tokenName = kubectl_manifest.join_token.name
      }
      proxyAddr       = "${var.proxy_address}:443"
      kubeClusterName = var.testbed_name
      labels = {
        env     = var.env
        team    = var.team
        testbed = var.testbed_name
      }
      annotations = {
        serviceAccount = {
          "iam.gke.io/gcp-service-account" = google_service_account.testbed_nodes.email
        }
      }
    })
  ]

  depends_on = [time_sleep.wait_for_testbed, kubectl_manifest.join_token, google_service_account_iam_member.testbed_workload_identity]
}
