terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
    }
    kubectl = {
      source = "gavinbunney/kubectl"
    }
  }
}

resource "google_service_account" "ssh_node" {
  account_id   = replace(substr("${var.name_prefix}-ssh-node", 0, 30), "/-+$/", "")
  display_name = "Teleport SSH node SA for ${var.name_prefix}"
  project      = var.project_id
}

resource "google_project_iam_member" "ssh_node_log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.ssh_node.email}"
}

resource "google_project_iam_member" "ssh_node_metric_writer" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.ssh_node.email}"
}

resource "kubectl_manifest" "join_token" {
  apply_only = true
  yaml_body  = yamlencode({
    apiVersion = "resources.teleport.dev/v2"
    kind       = "TeleportProvisionToken"
    metadata = {
      name      = "${var.name_prefix}-gcp-ssh"
      namespace = var.teleport_namespace
    }
    spec = {
      roles       = ["Node"]
      join_method = "gcp"
      gcp = {
        allow = [
          {
            project_ids      = [var.project_id]
            service_accounts = [google_service_account.ssh_node.email]
          }
        ]
      }
    }
  })
}

data "google_compute_image" "ubuntu" {
  family  = "ubuntu-2204-lts"
  project = "ubuntu-os-cloud"
}

resource "google_compute_instance" "ssh_node" {
  count        = var.instance_count
  name         = "${var.name_prefix}-node-${count.index}"
  machine_type = var.machine_type
  zone         = "${var.region}-a"
  project      = var.project_id

  labels = {
    env        = var.env
    team       = var.team
    role       = "control-node"
    managed-by = "terraform"
    testbed    = var.testbed
  }

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.self_link
      size  = 20
      type  = "pd-standard"
    }
  }

  network_interface {
    subnetwork = var.subnetwork
    # No access_config block — no public IP; egress via Cloud NAT
  }

  metadata_startup_script = templatefile("${path.module}/userdata.tpl", {
    token_name       = kubectl_manifest.join_token.name
    proxy_address    = var.proxy_address
    teleport_version = var.teleport_version
    env              = var.env
    team             = var.team
    testbed          = var.testbed
  })

  service_account {
    email  = google_service_account.ssh_node.email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  depends_on = [kubectl_manifest.join_token]
}
