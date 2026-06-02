variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "name" {
  description = "Name prefix used for GCP resources (Firestore, GCS, GSA). E.g. 'presales-gke'"
  type        = string
}

variable "env" {
  description = "Environment label (e.g. prod, dev)"
  type        = string
  default     = "prod"
}

variable "team" {
  description = "Team label (e.g. platform)"
  type        = string
  default     = "platform"
}

variable "user" {
  description = "Email address for ACME certificate registration and resource labeling"
  type        = string
}

variable "proxy_address" {
  description = "Teleport cluster hostname, no port or scheme (e.g. teleport.corp.example.com)"
  type        = string
}

variable "teleport_version" {
  description = "Teleport Helm chart version to deploy (e.g. 18.0.0)"
  type        = string
}

variable "license_pem" {
  description = "Teleport Enterprise license PEM content. Leave empty for OSS."
  type        = string
  sensitive   = true
  default     = ""
}

variable "dns_zone_name" {
  description = "Cloud DNS managed zone name for DNS-01 ACME validation and A record creation (e.g. 'corp-example-com'). Leave empty to use the self-signed issuer."
  type        = string
  default     = ""
}

variable "enable_kms" {
  description = "Create a Cloud KMS key ring and key for Teleport CA key protection"
  type        = bool
  default     = false
}
