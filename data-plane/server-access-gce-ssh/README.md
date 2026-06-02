# Data-plane: server-access-gce-ssh

Deploys GCE instances simulating on-prem testbed control nodes. Nodes register with the Teleport control plane using GCP IAM joining (no static tokens).

Prerequisites: `control-plane/gke/` layers 1–3 must be applied first.

See [`terraform.tfvars.example`](./terraform.tfvars.example) for required variables.
