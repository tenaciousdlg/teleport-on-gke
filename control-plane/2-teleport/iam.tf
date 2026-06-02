resource "google_service_account" "teleport" {
  account_id   = "${var.name}-teleport"
  display_name = "Teleport service account for ${var.name}"
  project      = var.project_id
}

resource "google_project_iam_member" "teleport_datastore" {
  project = var.project_id
  role    = "roles/datastore.user"
  member  = "serviceAccount:${google_service_account.teleport.email}"
}

# Teleport calls EnsureIndexes() on startup via the Firestore Admin API,
# which requires datastore.indexes.create not included in datastore.user
resource "google_project_iam_member" "teleport_datastore_index" {
  project = var.project_id
  role    = "roles/datastore.indexAdmin"
  member  = "serviceAccount:${google_service_account.teleport.email}"
}

resource "google_project_iam_member" "teleport_trace" {
  project = var.project_id
  role    = "roles/cloudtrace.agent"
  member  = "serviceAccount:${google_service_account.teleport.email}"
}

resource "google_storage_bucket_iam_member" "teleport_session_recordings" {
  bucket = google_storage_bucket.session_recordings.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.teleport.email}"
}

locals {
  wi_members = [
    "serviceAccount:${var.project_id}.svc.id.goog[${kubernetes_namespace.teleport_cluster.metadata[0].name}/teleport-cluster]",
    "serviceAccount:${var.project_id}.svc.id.goog[${kubernetes_namespace.teleport_cluster.metadata[0].name}/teleport-cluster-proxy]",
    "serviceAccount:${var.project_id}.svc.id.goog[${kubernetes_namespace.teleport_cluster.metadata[0].name}/teleport-cluster-operator]",
  ]
}

resource "google_service_account_iam_member" "teleport_workload_identity" {
  for_each = toset(local.wi_members)

  service_account_id = google_service_account.teleport.name
  role               = "roles/iam.workloadIdentityUser"
  member             = each.value
}

resource "google_kms_crypto_key_iam_member" "teleport_kms" {
  count         = var.enable_kms ? 1 : 0
  crypto_key_id = google_kms_crypto_key.teleport_ca[0].id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${google_service_account.teleport.email}"
}

# cert-manager GSA (only created when Cloud DNS zone is provided for ACME DNS-01)
resource "google_service_account" "cert_manager" {
  count        = var.dns_zone_name != "" ? 1 : 0
  account_id   = "${var.name}-cert-manager"
  display_name = "cert-manager DNS-01 service account for ${var.name}"
  project      = var.project_id
}

resource "google_project_iam_member" "cert_manager_dns_admin" {
  count   = var.dns_zone_name != "" ? 1 : 0
  project = var.project_id
  role    = "roles/dns.admin"
  member  = "serviceAccount:${google_service_account.cert_manager[0].email}"
}

resource "google_service_account_iam_member" "cert_manager_workload_identity" {
  count              = var.dns_zone_name != "" ? 1 : 0
  service_account_id = google_service_account.cert_manager[0].name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[cert-manager/cert-manager]"
}
