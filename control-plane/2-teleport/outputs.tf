output "teleport_url" {
  description = "Teleport web UI URL"
  value       = var.dns_zone_name != "" ? "https://${var.proxy_address}" : "https://${try(data.kubernetes_service.teleport_cluster.status[0].load_balancer[0].ingress[0].ip, "pending")}"
}

output "teleport_version" {
  description = "Deployed Teleport version"
  value       = var.teleport_version
}

output "cluster_name" {
  description = "Teleport cluster name"
  value       = var.proxy_address
}

output "gke_cluster_name" {
  description = "GKE cluster name from remote state"
  value       = data.terraform_remote_state.gke.outputs.cluster_name
}

output "session_recordings_bucket" {
  description = "GCS bucket for session recordings"
  value       = google_storage_bucket.session_recordings.name
}

output "teleport_service_account_email" {
  description = "GSA email used by Teleport pods via Workload Identity"
  value       = google_service_account.teleport.email
}

output "ilb_ip" {
  description = "Internal load balancer IP (available after apply)"
  value       = try(data.kubernetes_service.teleport_cluster.status[0].load_balancer[0].ingress[0].ip, "pending")
}

output "certificate_status" {
  description = "Commands to check TLS certificate status"
  value = {
    check_certificate = "kubectl describe certificate teleport-tls -n teleport-cluster"
    check_secret      = "kubectl describe secret teleport-tls -n teleport-cluster"
    cert_manager_logs = "kubectl logs -n cert-manager deployment/cert-manager"
  }
}
