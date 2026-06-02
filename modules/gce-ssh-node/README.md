# Module: gce-ssh-node

Deploys one or more GCE instances as Teleport SSH nodes using GCP IAM joining (no static tokens). Each instance gets a dedicated GSA and a `TeleportProvisionTokenV2` CRD applied to the control plane cluster.

The `kubectl` provider must be configured by the module consumer to point at the Teleport control plane cluster.

## Usage

```hcl
module "ssh_nodes" {
  source = "../../modules/gce-ssh-node"

  project_id         = var.project_id
  region             = var.region
  name_prefix        = "testbed-alpha"
  env                = "dev"
  team               = "platform"
  testbed            = "testbed-alpha"
  proxy_address      = "teleport.corp.example.com"
  teleport_version   = "18.6.4"
  subnetwork         = google_compute_subnetwork.testbed.self_link
  instance_count     = 3
  teleport_namespace = "teleport-cluster"
}
```

## Node labels

Each SSH node registers with these labels:

| Label    | Value |
|----------|-------|
| env      | `var.env` |
| team     | `var.team` |
| role     | `control-node` |
| testbed  | `var.testbed` |

The `ssh-control` Teleport role in the GKE control plane's 3-rbac layer matches `role=control-node`.
