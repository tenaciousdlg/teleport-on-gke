terraform {
  required_providers {
    teleport = {
      source  = "terraform.releases.teleport.dev/gravitational/teleport"
      version = "~> 18.0"
    }
  }
}

# Requires a running port-forward and a valid tsh session:
#   kubectl port-forward -n teleport-cluster svc/teleport-cluster 4443:443 &
#   tsh login --proxy=<proxy_address> --insecure
provider "teleport" {
  addr         = "localhost:${var.teleport_local_port}"
  profile_name = var.proxy_address
  insecure     = true
}
