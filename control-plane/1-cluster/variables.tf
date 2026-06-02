variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region to deploy resources in"
  type        = string
  default     = "us-central1"
}

variable "name" {
  description = "Name prefix for the cluster and all resources (e.g. 'presales-gke')"
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
  description = "Email of the user managing this deployment (used for resource labels)"
  type        = string
}

variable "machine_type" {
  description = "GCE machine type for GKE nodes"
  type        = string
  default     = "e2-standard-2"
}

variable "node_count" {
  description = "Initial node count (autoscaling min=1, max=4)"
  type        = number
  default     = 2
}

variable "cidr_vpc" {
  description = "Primary VPC CIDR range"
  type        = string
  default     = "10.100.0.0/16"
}

variable "cidr_subnet" {
  description = "Primary subnet CIDR range for GKE nodes"
  type        = string
  default     = "10.100.1.0/24"
}

variable "cidr_pods" {
  description = "Secondary range for GKE pods"
  type        = string
  default     = "10.101.0.0/16"
}

variable "cidr_services" {
  description = "Secondary range for GKE services"
  type        = string
  default     = "10.102.0.0/20"
}

variable "cidr_master" {
  description = "CIDR for the GKE control plane (must be /28)"
  type        = string
  default     = "10.103.0.0/28"
}
