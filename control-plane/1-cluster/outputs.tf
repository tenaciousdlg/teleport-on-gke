output "cluster_name" {
  description = "Name of the GKE cluster"
  value       = google_container_cluster.teleport.name
}

output "cluster_endpoint" {
  description = "Endpoint for the GKE control plane"
  value       = "https://${google_container_cluster.teleport.endpoint}"
}

output "cluster_ca_certificate" {
  description = "Base64-encoded cluster CA certificate"
  value       = google_container_cluster.teleport.master_auth[0].cluster_ca_certificate
  sensitive   = true
}

output "network_name" {
  description = "Name of the VPC network"
  value       = google_compute_network.teleport.name
}

output "subnetwork_name" {
  description = "Name of the primary subnetwork"
  value       = google_compute_subnetwork.teleport.name
}

output "node_service_account_email" {
  description = "Email of the GKE node service account"
  value       = google_service_account.gke_nodes.email
}

output "region" {
  description = "GCP region"
  value       = var.region
}

output "project_id" {
  description = "GCP project ID"
  value       = var.project_id
}

output "kubeconfig_command" {
  description = "Command to configure kubectl for this cluster"
  value       = "gcloud container clusters get-credentials ${google_container_cluster.teleport.name} --region ${var.region} --project ${var.project_id}"
}

output "bastion_ssh_command" {
  description = "IAP tunnel SSH command for the bastion VM"
  value       = "gcloud compute ssh ${google_compute_instance.bastion.name} --tunnel-through-iap --project ${var.project_id} --zone ${google_compute_instance.bastion.zone}"
}

output "bastion_name" {
  description = "Bastion instance name"
  value       = google_compute_instance.bastion.name
}
