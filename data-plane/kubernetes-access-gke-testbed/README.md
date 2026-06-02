# Data-plane: kubernetes-access-gke-testbed

Deploys a small GKE cluster simulating an on-prem Kubernetes testbed and registers it with Teleport via the `teleport-kube-agent` Helm chart.

The join token CRD is created on the **control plane** cluster; the kube-agent is deployed to the **testbed** cluster. Two separate providers handle this split.

Prerequisites: `control-plane/gke/` layers 1–3 must be applied first.

See [`terraform.tfvars.example`](./terraform.tfvars.example) for required variables.
