resource "google_service_account" "bastion" {
  account_id   = "${var.name}-bastion"
  display_name = "Bastion service account for ${var.name}"
}

resource "google_project_iam_member" "bastion_log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.bastion.email}"
}

# IAP TCP tunneling requires this source range for SSH
resource "google_compute_firewall" "iap_ssh" {
  name    = "${var.name}-iap-ssh"
  network = google_compute_network.teleport.id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"]
}

resource "google_compute_instance" "bastion" {
  name         = "${var.name}-bastion"
  machine_type = "e2-micro"
  zone         = "${var.region}-a"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 20
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.teleport.id
    # No access_config block = no public IP; IAP tunnel is the only ingress
  }

  service_account {
    email  = google_service_account.bastion.email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  metadata_startup_script = <<-SCRIPT
    #!/bin/bash
    set -euo pipefail
    apt-get update -q
    apt-get install -yq curl wget jq dnsutils netcat-openbsd

    # Install gcloud (for get-credentials)
    curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" > /etc/apt/sources.list.d/google-cloud-sdk.list
    apt-get update -q && apt-get install -yq google-cloud-cli google-cloud-cli-gke-gcloud-auth-plugin kubectl
  SCRIPT

  labels = {
    env  = var.env
    role = "bastion"
  }

  tags = ["bastion"]
}
