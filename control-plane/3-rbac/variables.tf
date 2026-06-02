variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region (needed for the google provider)"
  type        = string
  default     = "us-central1"
}

variable "proxy_address" {
  description = "Teleport cluster hostname, no port or scheme (e.g. teleport.corp.example.com)"
  type        = string
}

variable "teleport_namespace" {
  description = "Kubernetes namespace where Teleport is installed"
  type        = string
  default     = "teleport-cluster"
}

variable "teleport_local_port" {
  description = "Local port for kubectl port-forward to the Teleport proxy (4443 avoids sudo for 443)"
  type        = number
  default     = 4443
}

variable "google_domain" {
  description = "Google Workspace domain for OIDC email claim matching (e.g. corp.example.com)"
  type        = string
}

variable "oidc_client_id" {
  description = "Google OAuth 2.0 client ID"
  type        = string
  sensitive   = true
}

variable "oidc_client_secret" {
  description = "Google OAuth 2.0 client secret"
  type        = string
  sensitive   = true
}

variable "access_list_owner" {
  description = "Teleport username (email) of the access list owner — must match the user running terraform apply"
  type        = string
}

variable "access_list_members" {
  description = "Map of access list name to member usernames (email addresses). Add users here before they log in."
  type        = map(list(string))
  default = {
    devs      = []
    engineers = []
  }
}

variable "autoupdate_mode" {
  description = "Agent auto-update mode: 'enabled' for automatic rolling updates, 'disabled' to manage manually"
  type        = string
  default     = "enabled"
}
