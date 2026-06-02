locals {
  kms_auth_config = var.enable_kms ? {
    teleportConfig = {
      auth_service = {
        ca_key_params = {
          gcp_kms = {
            key_ring         = "projects/${var.project_id}/locations/${var.region}/keyRings/${google_kms_key_ring.teleport[0].name}"
            protocol_version = 2
          }
        }
      }
    }
  } : {}
}

resource "helm_release" "teleport_cluster" {
  name       = "teleport-cluster"
  namespace  = kubernetes_namespace.teleport_cluster.metadata[0].name
  repository = "https://charts.releases.teleport.dev"
  chart      = "teleport-cluster"
  version    = var.teleport_version
  wait       = true
  timeout    = 300

  values = [
    jsonencode({
      clusterName       = var.proxy_address
      proxyListenerMode = "multiplex"
      acme              = false
      tls               = { existingSecretName = "teleport-tls" }
      enterprise        = var.license_pem != ""
      authentication    = { type = "oidc" }
      labels            = { env = var.env, team = var.team }
      chartMode         = "gcp"
      gcp = {
        projectId              = var.project_id
        backendTable           = "${var.name}-backend"
        auditLogTable          = "${var.name}-audit-log"
        sessionRecordingBucket = google_storage_bucket.session_recordings.name
        # Empty string disables the credentials secret mount and uses Workload Identity instead
        credentialSecretName   = ""
      }
      serviceAccount = { create = false, name = "teleport-cluster" }
      auth           = merge({ serviceAccount = { create = false, name = "teleport-cluster" } }, local.kms_auth_config)
      proxy          = { serviceAccount = { create = false, name = "teleport-cluster-proxy" } }
      operator       = { enabled = true, serviceAccount = { create = false, name = "teleport-cluster-operator" } }
      service        = { type = "LoadBalancer" }
      # annotations.service is the correct chart path (service.annotations is silently ignored)
      annotations = {
        service = {
          "networking.gke.io/load-balancer-type" = "Internal"
          # Allows testbeds connecting via Cloud Interconnect from other regions to reach this ILB
          "networking.gke.io/internal-load-balancer-allow-global-access" = "true"
        }
      }
    })
  ]

  depends_on = [
    kubectl_manifest.teleport_certificate,
    kubernetes_secret.license,
    kubernetes_service_account.teleport_auth,
    kubernetes_service_account.teleport_proxy,
    kubernetes_service_account.teleport_operator,
    google_service_account_iam_member.teleport_workload_identity,
    google_project_iam_member.teleport_datastore,
    google_storage_bucket_iam_member.teleport_session_recordings,
  ]
}

resource "time_sleep" "wait_for_operator" {
  depends_on      = [helm_release.teleport_cluster]
  create_duration = "60s"
}
