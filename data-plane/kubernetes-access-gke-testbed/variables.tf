variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region for the testbed GKE cluster"
  type        = string
  default     = "us-central1"
}

variable "env" {
  description = "Environment label for the testbed cluster (e.g. dev)"
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

variable "testbed_name" {
  description = "Name for this testbed cluster as it will appear in Teleport (e.g. testbed-alpha)"
  type        = string
  default     = "testbed-alpha"
}

variable "proxy_address" {
  description = "Teleport proxy address, hostname only, no port or scheme"
  type        = string
}

variable "teleport_version" {
  description = "Teleport kube-agent Helm chart version (e.g. 18.0.0)"
  type        = string
}

variable "machine_type" {
  description = "GCE machine type for testbed GKE nodes"
  type        = string
  default     = "e2-small"
}

variable "node_count" {
  description = "Number of nodes in the testbed GKE cluster"
  type        = number
  default     = 2
}

variable "teleport_namespace" {
  description = "Teleport Kubernetes namespace on the control plane cluster (for the join token CRD)"
  type        = string
  default     = "teleport-cluster"
}

# Control plane cluster connection — provided as vars to avoid cross-directory state deps
variable "control_plane_network_name" {
  description = "Name of the control plane VPC network. Testbed subnet is created here so it can reach the internal LB."
  type        = string
}

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
