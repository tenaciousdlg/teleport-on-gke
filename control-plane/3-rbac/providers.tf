terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14"
    }
    teleport = {
      source  = "terraform.releases.teleport.dev/gravitational/teleport"
      version = "~> 18.0"
    }
  }
}

provider "teleport" {
  addr         = "localhost:${var.teleport_local_port}"
  profile_name = var.proxy_address
  insecure     = true
}

data "terraform_remote_state" "gke" {
  backend = "local"
  config = {
    path = "../1-cluster/terraform.tfstate"
  }
}

data "google_client_config" "default" {}

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "kubernetes" {
  host                   = data.terraform_remote_state.gke.outputs.cluster_endpoint
  cluster_ca_certificate = base64decode(data.terraform_remote_state.gke.outputs.cluster_ca_certificate)
  token                  = data.google_client_config.default.access_token
}

provider "kubectl" {
  host                   = data.terraform_remote_state.gke.outputs.cluster_endpoint
  cluster_ca_certificate = base64decode(data.terraform_remote_state.gke.outputs.cluster_ca_certificate)
  token                  = data.google_client_config.default.access_token
  load_config_file       = false
}

data "kubernetes_namespace" "teleport_cluster" {
  metadata {
    name = var.teleport_namespace
  }
}
