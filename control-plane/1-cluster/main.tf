terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
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

resource "google_compute_network" "teleport" {
  name                    = "${var.name}-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "teleport" {
  name          = "${var.name}-subnet"
  region        = var.region
  network       = google_compute_network.teleport.id
  ip_cidr_range = var.cidr_subnet

  secondary_ip_range {
    range_name    = "${var.name}-pods"
    ip_cidr_range = var.cidr_pods
  }

  secondary_ip_range {
    range_name    = "${var.name}-services"
    ip_cidr_range = var.cidr_services
  }
}

resource "google_compute_router" "teleport" {
  name    = "${var.name}-router"
  region  = var.region
  network = google_compute_network.teleport.id
}

resource "google_compute_router_nat" "teleport" {
  name                               = "${var.name}-nat"
  router                             = google_compute_router.teleport.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

resource "google_service_account" "gke_nodes" {
  account_id   = "${var.name}-gke-nodes"
  display_name = "GKE node service account for ${var.name}"
}

resource "google_project_iam_member" "gke_nodes_log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

resource "google_project_iam_member" "gke_nodes_metric_writer" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

resource "google_project_iam_member" "gke_nodes_monitoring_viewer" {
  project = var.project_id
  role    = "roles/monitoring.viewer"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

resource "google_project_iam_member" "gke_nodes_artifact_reader" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

resource "google_container_cluster" "teleport" {
  name     = "${var.name}-cluster"
  location = var.region

  deletion_protection = false

  network    = google_compute_network.teleport.id
  subnetwork = google_compute_subnetwork.teleport.id

  remove_default_node_pool = true
  initial_node_count       = 1

  release_channel {
    channel = "REGULAR"
  }

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  ip_allocation_policy {
    cluster_secondary_range_name  = "${var.name}-pods"
    services_secondary_range_name = "${var.name}-services"
  }

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = var.cidr_master
  }

  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = "0.0.0.0/0"
      display_name = "all"
    }
  }
}

resource "google_container_node_pool" "primary" {
  name     = "${var.name}-primary"
  cluster  = google_container_cluster.teleport.id
  location = var.region

  autoscaling {
    min_node_count = 1
    max_node_count = 4
  }

  node_config {
    machine_type    = var.machine_type
    service_account = google_service_account.gke_nodes.email
    oauth_scopes    = ["https://www.googleapis.com/auth/cloud-platform"]

    shielded_instance_config {
      enable_secure_boot = true
    }

    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    labels = {
      env  = var.env
      team = var.team
    }
  }
}

# Allow internal TCP within the VPC (node-to-node and pod communication)
resource "google_compute_firewall" "internal" {
  name    = "${var.name}-internal"
  network = google_compute_network.teleport.id

  allow {
    protocol = "tcp"
  }

  allow {
    protocol = "udp"
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = [var.cidr_vpc]
}

# GCP health check ranges required for ILB health probes
resource "google_compute_firewall" "health_checks" {
  name    = "${var.name}-health-checks"
  network = google_compute_network.teleport.id

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges = ["35.191.0.0/16", "130.211.0.0/22"]
}

# GKE master must reach node ports for admission webhooks
resource "google_compute_firewall" "master_to_nodes" {
  name    = "${var.name}-master-to-nodes"
  network = google_compute_network.teleport.id

  allow {
    protocol = "tcp"
    ports    = ["443", "8443"]
  }

  source_ranges = [var.cidr_master]
}
