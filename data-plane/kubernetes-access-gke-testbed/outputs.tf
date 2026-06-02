output "testbed_cluster_name" {
  description = "GKE testbed cluster name"
  value       = google_container_cluster.testbed.name
}

output "testbed_cluster_endpoint" {
  description = "GKE testbed cluster endpoint"
  value       = "https://${google_container_cluster.testbed.endpoint}"
}

output "teleport_cluster_name" {
  description = "Name the testbed cluster will appear under in Teleport"
  value       = var.testbed_name
}

output "kubeconfig_command" {
  description = "Command to configure kubectl for the testbed cluster"
  value       = "gcloud container clusters get-credentials ${google_container_cluster.testbed.name} --region ${var.region} --project ${var.project_id}"
}

output "join_token_name" {
  description = "Name of the join token created on the control plane"
  value       = kubectl_manifest.join_token.name
}
