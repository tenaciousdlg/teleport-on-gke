terraform {
  required_version = ">= 1.6.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  default_labels = {
    teleport-creator = replace(split("@", var.user)[0], ".", "-")
    env              = var.env
    managed-by       = "terraform"
  }
}

# kubectl provider points at the Teleport control plane GKE cluster so that
# TeleportProvisionTokenV2 CRDs are created there, not on the testbed cluster.
provider "kubectl" {
  host                   = var.control_plane_cluster_endpoint
  cluster_ca_certificate = base64decode(var.control_plane_cluster_ca_certificate)
  token                  = var.control_plane_cluster_token
  load_config_file       = false
}

module "ssh_nodes" {
  source = "../../modules/gce-ssh-node"

  project_id         = var.project_id
  region             = var.region
  name_prefix        = "${replace(split("@", var.user)[0], ".", "-")}-${var.testbed}"
  env                = var.env
  team               = var.team
  testbed            = var.testbed
  proxy_address      = var.proxy_address
  teleport_version   = var.teleport_version
  subnetwork         = var.subnetwork
  machine_type       = var.machine_type
  instance_count     = var.instance_count
  teleport_namespace = var.teleport_namespace
}
