variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region for GCE instances"
  type        = string
  default     = "us-central1"
}

variable "env" {
  description = "Environment label (e.g. dev, prod)"
  type        = string
  default     = "dev"
}

variable "team" {
  description = "Team label"
  type        = string
  default     = "platform"
}

variable "user" {
  description = "Email of the user managing this deployment"
  type        = string
}

variable "testbed" {
  description = "Testbed identifier (used as a label on nodes, e.g. testbed-alpha)"
  type        = string
  default     = "testbed-alpha"
}

variable "proxy_address" {
  description = "Teleport proxy address, hostname only, no port or scheme"
  type        = string
}

variable "teleport_version" {
  description = "Teleport agent version to install (e.g. 18.0.0)"
  type        = string
}

variable "subnetwork" {
  description = "Subnetwork self-link or name for GCE instances"
  type        = string
}

variable "machine_type" {
  description = "GCE machine type for the SSH nodes"
  type        = string
  default     = "e2-micro"
}

variable "instance_count" {
  description = "Number of GCE SSH nodes to create"
  type        = number
  default     = 3
}

variable "teleport_namespace" {
  description = "Teleport Kubernetes namespace (for the join token CRD)"
  type        = string
  default     = "teleport-cluster"
}

# Control plane cluster info supplied directly as vars to avoid cross-directory state deps
variable "control_plane_cluster_endpoint" {
  description = "GKE control plane cluster endpoint URL (e.g. https://1.2.3.4)"
  type        = string
}

variable "control_plane_cluster_ca_certificate" {
  description = "Base64-encoded CA certificate for the control plane GKE cluster"
  type        = string
  sensitive   = true
}

variable "control_plane_cluster_token" {
  description = "Bearer token for authenticating to the control plane GKE cluster"
  type        = string
  sensitive   = true
}
