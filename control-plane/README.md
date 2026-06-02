# Teleport Control Plane on GKE

> **Demo Environment**: optimized for POV demos. Not for production use.

Three-layer deployment of Teleport Enterprise on GKE with Google OIDC, Firestore, GCS session recordings, and an internal L4 load balancer. Designed for organizations that must not expose load balancers publicly (Google org policy) and require ALPN multiplexing on port 443.

## Layout

```
control-plane/gke/
├── 1-cluster/    # GKE cluster, VPC, Cloud NAT
├── 2-teleport/   # Teleport deployment + Firestore + GCS + KMS + cert-manager
└── 3-rbac/       # Google OIDC connector, roles, Access Lists
```

## Quick Start

### 1) Deploy GKE cluster (~10 min)

```bash
cd control-plane/gke/1-cluster
export TF_VAR_project_id="your-gcp-project"
export TF_VAR_region="us-central1"
export TF_VAR_name="presales-gke"
export TF_VAR_user="you@example.com"
terraform init
terraform apply
```

### 2) Deploy Teleport

```bash
cd ../2-teleport
export TF_VAR_project_id="your-gcp-project"
export TF_VAR_region="us-central1"
export TF_VAR_name="presales-gke"
export TF_VAR_proxy_address="teleport.corp.example.com"
export TF_VAR_user="you@example.com"
export TF_VAR_teleport_version="18.6.4"
export TF_VAR_license_pem="$(cat /path/to/license.pem)"
# Optional: export TF_VAR_dns_zone_name="corp-example-com"
terraform init
terraform apply
```

### 3) Apply RBAC

```bash
cd ../3-rbac
export TF_VAR_project_id="your-gcp-project"
export TF_VAR_proxy_address="teleport.corp.example.com"
export TF_VAR_google_domain="example.com"
export TF_VAR_oidc_client_id="XXXXXX.apps.googleusercontent.com"
export TF_VAR_oidc_client_secret="GOCSPX-XXXXXXXXXX"
terraform init
terraform apply
```

## Design Notes

**Internal LB only**: The Kubernetes service uses `networking.gke.io/load-balancer-type: Internal`. This satisfies Google org policies that prohibit external load balancers. The `allow-global-access` annotation allows testbeds in other regions connecting via Cloud Interconnect to reach the ILB.

**ALPN multiplex**: `proxyListenerMode: multiplex` puts SSH, kubectl, web UI, and agent dial-back on port 443. An L7 HTTPS LB would break this — L4 TCP is required.

**Workload Identity**: GKE service accounts are annotated with `iam.gke.io/gcp-service-account` to bind to a GSA. No static keys or credentials are used.

**Firestore**: Uses the `(default)` Firestore database. The cluster name is written to Firestore on first auth startup and is immutable — changing `proxy_address` after first deploy requires deleting the backend collection and restarting auth so it reinitializes with the new name.

**Google OIDC**: No group claims are available in Google OIDC tokens. Access Lists are used for role assignment instead of `claims_to_roles` group matching.

**DNS-01 optional**: Set `dns_zone_name` to your Cloud DNS managed zone name to enable Let's Encrypt certificates via DNS-01. Leave empty to use a self-signed certificate (requires browsers to accept the warning or adding the CA to your trust store).

**Google client access — L4 proxy required**: TSH does not work through Google's L7 world proxy (`CORP` HTTP proxy) because it performs TLS certificate inspection that breaks Teleport's PKI. TSH works through the L4 streaming world proxy, which wraps raw TCP without cert inspection. Engineers must point TSH at the L4 streaming proxy (e.g., `HTTP_PROXY=socks5://localhost:<port>`) or apply for a no-inspect exemption for the Teleport hostname. Web UI access via browser is unaffected (the L7 proxy handles HTTPS applications fine).

## RBAC Model

| Access List | Type   | Roles |
|-------------|--------|-------|
| everyone    | static | base-user |
| engineers   | static | k8s-dev-access, engineer, ssh-control |
| security-team | static | k8s-admin, ssh-control, auditor, editor |

Access Lists are `type: static` — members are added manually via the Teleport web UI or `tctl`. Use Google OIDC group sync if available, or manage membership directly.

## Teardown

Destroy in reverse layer order: `3-rbac` → `2-teleport` → `1-cluster`.

### 2-teleport: CRD finalizer hang

`terraform destroy` hangs on Teleport CRD and namespace deletion when the operator is already gone. Strip finalizers **before** running destroy, or in a second terminal while destroy is running:

```bash
# Step 1: strip finalizers from all Teleport CR instances in the namespace
for crd in $(kubectl get crds -o name | grep teleport | sed 's|customresourcedefinition.apiextensions.k8s.io/||'); do
  kubectl get "$crd" -n teleport-cluster -o name 2>/dev/null | \
    xargs -I{} kubectl patch {} -n teleport-cluster \
      -p '{"metadata":{"finalizers":[]}}' --type=merge 2>/dev/null
done

# Step 2: strip finalizers from the CRD definitions themselves
kubectl get crds -o name | grep teleport \
  | xargs -I{} kubectl patch {} -p '{"metadata":{"finalizers":[]}}' --type=merge

# Step 3: patch the namespace if it's stuck terminating
kubectl patch namespace teleport-cluster \
  -p '{"metadata":{"finalizers":[]}}' --type=merge 2>/dev/null || true
```

If destroy times out and exits with an error, re-run it — subsequent runs complete quickly once finalizers are clear.

## Troubleshooting

### Cluster name shows wrong value after `proxy_address` change

This only happens if you change `proxy_address` after the first deploy. The cluster identity is written to Firestore at first auth startup and is never updated in-place. Set `proxy_address` correctly before first apply and this never occurs. If you do need to fix it:

```bash
# 1. Scale auth to zero
kubectl scale deployment teleport-cluster-auth -n teleport-cluster --replicas=0

# 2. Delete the Firestore backend collection via the GCP Console:
#    Firestore → presales-gke-backend → delete collection
#    (do NOT delete presales-gke-audit-log)

# 3. Scale auth back up — it reinitializes with the current clusterName from Helm
kubectl scale deployment teleport-cluster-auth -n teleport-cluster --replicas=1

# 4. Restart the operator — its embedded tbot credentials were signed by the old CA
kubectl rollout restart deployment/teleport-cluster-operator -n teleport-cluster

# 5. Restart the proxy — same CA trust issue
kubectl rollout restart deployment/teleport-cluster-proxy -n teleport-cluster

# 6. Clear tsh's cached CA and re-login
rm -rf ~/.tsh/keys/<proxy-address>
tsh login --proxy=<proxy-address> --insecure --auth=google
```

## Accessing the Cluster

The ILB is internal-only, so access from a laptop requires a port-forward:

```bash
# Port 443 is privileged — sudo required on macOS/Linux
sudo kubectl port-forward -n teleport-cluster svc/teleport-cluster 443:443
```

Then in a second terminal:

```bash
tsh login --proxy=teleport-gke.teleportsedemo.com --auth=google
```

This opens `accounts.google.com` in the browser for OIDC auth. If tsh silently reuses a cached cert (no browser opens), run `tsh logout` first to force a fresh login.

## Teleport Updates

Update `TF_VAR_teleport_version` and re-apply only `2-teleport`:

```bash
cd 2-teleport
export TF_VAR_teleport_version=18.7.2
terraform apply
```
