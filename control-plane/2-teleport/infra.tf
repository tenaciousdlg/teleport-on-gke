resource "google_storage_bucket" "session_recordings" {
  name          = "${var.name}-session-recordings-${data.google_client_config.default.project}"
  location      = var.region
  project       = var.project_id
  force_destroy = true

  uniform_bucket_level_access = true

  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }

  lifecycle_rule {
    condition {
      age = 90
    }
    action {
      type          = "SetStorageClass"
      storage_class = "COLDLINE"
    }
  }

  lifecycle_rule {
    condition {
      age = 365
    }
    action {
      type = "Delete"
    }
  }
}

resource "google_kms_key_ring" "teleport" {
  count    = var.enable_kms ? 1 : 0
  name     = "${var.name}-keyring"
  location = var.region
  project  = var.project_id
}

# rotation_period intentionally omitted — Teleport manages key rotation itself
resource "google_kms_crypto_key" "teleport_ca" {
  count    = var.enable_kms ? 1 : 0
  name     = "${var.name}-ca-key"
  key_ring = google_kms_key_ring.teleport[0].id
  purpose  = "ASYMMETRIC_SIGN"

  version_template {
    algorithm = "EC_SIGN_P256_SHA256"
  }
}
