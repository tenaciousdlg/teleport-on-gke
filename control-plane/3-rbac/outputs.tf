output "oidc_connector_name" {
  description = "Name of the Google OIDC connector"
  value       = teleport_oidc_connector.google.metadata.name
}

output "roles_created" {
  description = "Teleport roles managed by this layer"
  value       = ["base-user", "dev", "prod-readonly", "prod-access", "engineer"]
}

output "access_lists_created" {
  description = "Access lists managed by this layer"
  value       = ["devs", "engineers"]
}
