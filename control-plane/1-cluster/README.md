# GKE Control Plane — Layer 1: Cluster

Provisions the GKE cluster, VPC, Cloud NAT, and supporting GCP infrastructure. All subsequent layers read this layer's state via `terraform_remote_state`.

See [../README.md](../README.md) for the full GKE control plane deployment guide and layer sequence.
