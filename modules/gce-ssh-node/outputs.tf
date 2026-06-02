output "instance_names" {
  description = "Names of the GCE instances"
  value       = google_compute_instance.ssh_node[*].name
}

output "private_ips" {
  description = "Internal IP addresses of the GCE instances"
  value       = [for inst in google_compute_instance.ssh_node : inst.network_interface[0].network_ip]
}

output "service_account_email" {
  description = "Email of the GCE node service account"
  value       = google_service_account.ssh_node.email
}

output "join_token_name" {
  description = "Name of the GCP join token"
  value       = kubectl_manifest.join_token.name
}
