output "instance_names" {
  description = "Names of the GCE SSH node instances"
  value       = module.ssh_nodes.instance_names
}

output "private_ips" {
  description = "Internal IP addresses of the GCE SSH nodes"
  value       = module.ssh_nodes.private_ips
}

output "service_account_email" {
  description = "GSA email used by the SSH nodes"
  value       = module.ssh_nodes.service_account_email
}

output "join_token_name" {
  description = "Name of the GCP join token created in the control plane"
  value       = module.ssh_nodes.join_token_name
}
