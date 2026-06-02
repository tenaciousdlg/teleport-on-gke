# GKE Control Plane — Layer 3: RBAC

Configures the Google OIDC connector, login rules, Kubernetes and SSH access roles, and Access Lists.

See [../README.md](../README.md) for the full GKE control plane deployment guide and layer sequence.

## Access List membership

`terraform apply` creates the access lists and roles but does not populate membership. After applying, add users to the appropriate access list via tctl:

```bash
AUTH_POD=$(kubectl get pods -n teleport-cluster -l app.kubernetes.io/component=auth -o jsonpath='{.items[0].metadata.name}')

# Engineers — k8s-dev-access + engineer + ssh-control
kubectl exec -n teleport-cluster $AUTH_POD -- \
  tctl acl users add engineers "you@example.com" "" "engineer"

# Everyone — base-user (all authenticated users)
kubectl exec -n teleport-cluster $AUTH_POD -- \
  tctl acl users add everyone "you@example.com" "" "all users"

# Security team — k8s-admin + ssh-control + auditor + editor
kubectl exec -n teleport-cluster $AUTH_POD -- \
  tctl acl users add security-team "you@example.com" "" "security admin"
```

The `TeleportAccessListMember` resource is not exposed as a Kubernetes CRD by the operator, so membership cannot be managed via Terraform at this time.

Users must re-login after being added to an access list for the new roles to take effect.
