# Teleport Enterprise on GKE

> **Demo environment**: optimized for POV demos and workshops. Not for production use.

Terraform for a full Teleport Enterprise deployment on GKE — control plane, RBAC, and data-plane test infrastructure — with Google OIDC, Firestore, GCS session recordings, and an internal L4 load balancer. Built for organizations that can't expose load balancers publicly and need ALPN multiplexing on port 443.

## Layout

```
control-plane/
├── 1-cluster/    # GKE cluster, VPC, Cloud NAT
├── 2-teleport/   # Teleport deployment: Firestore, GCS, Workload Identity, cert-manager
└── 3-rbac/       # Google OIDC connector, roles, Access Lists
data-plane/
├── kubernetes-access-gke-testbed/  # on-prem-style K8s testbed registered via teleport-kube-agent
└── server-access-gce-ssh/          # GCE nodes registered via GCP IAM joining (no static tokens)
modules/
└── gce-ssh-node/                   # shared GCE SSH node module
```

## Quick start

Apply the control-plane layers in order — each reads the prior layer's state via `terraform_remote_state`:

```bash
cd control-plane/1-cluster && terraform init && terraform apply
cd ../2-teleport && terraform init && terraform apply
cd ../3-rbac && terraform init && terraform apply
```

Then apply any data-plane module to register test infrastructure against the cluster. See [control-plane/README.md](control-plane/README.md) for the full deployment guide.
