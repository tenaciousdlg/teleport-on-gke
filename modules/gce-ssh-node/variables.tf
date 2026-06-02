variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region for the GCE instance"
  type        = string
}

variable "name_prefix" {
  description = "Name prefix for GCE instances and supporting resources"
  type        = string
}

variable "env" {
  description = "Environment label (e.g. dev, prod)"
  type        = string
}

variable "team" {
  description = "Team label"
  type        = string
}

variable "testbed" {
  description = "Testbed identifier label (e.g. testbed-alpha). Used in SSH node labels."
  type        = string
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
  description = "Subnetwork self-link or name for the GCE instances"
  type        = string
}

variable "machine_type" {
  description = "GCE machine type for SSH nodes"
  type        = string
  default     = "e2-micro"
}

variable "instance_count" {
  description = "Number of GCE instances to create"
  type        = number
  default     = 3
}

variable "teleport_namespace" {
  description = "Kubernetes namespace where the Teleport provision token CRD will be created"
  type        = string
  default     = "teleport-cluster"
}
