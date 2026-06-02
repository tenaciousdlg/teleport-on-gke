resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  namespace        = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  version          = "v1.16.2"
  create_namespace = true
  wait             = true
  timeout          = 300

  set {
    name  = "crds.enabled"
    value = "true"
  }

  set {
    name  = "global.leaderElection.namespace"
    value = "cert-manager"
  }

  # Annotate the SA before pod start so Workload Identity credentials are available for DNS-01 challenges.
  dynamic "set" {
    for_each = var.dns_zone_name != "" ? [google_service_account.cert_manager[0].email] : []
    content {
      name  = "serviceAccount.annotations.iam\\.gke\\.io/gcp-service-account"
      value = set.value
    }
  }

  depends_on = [google_service_account_iam_member.cert_manager_workload_identity]
}

resource "time_sleep" "wait_for_cert_manager" {
  depends_on      = [helm_release.cert_manager]
  create_duration = "90s"
}

resource "kubectl_manifest" "letsencrypt_prod_issuer" {
  count      = var.dns_zone_name != "" ? 1 : 0
  depends_on = [time_sleep.wait_for_cert_manager]
  yaml_body = yamlencode({
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata   = { name = "letsencrypt-prod" }
    spec = {
      acme = {
        server              = "https://acme-v02.api.letsencrypt.org/directory"
        email               = var.user
        privateKeySecretRef = { name = "letsencrypt-prod-account-key" }
        solvers = [
          {
            dns01 = {
              cloudDNS = {
                project = var.project_id
              }
            }
          }
        ]
      }
    }
  })
}

resource "kubectl_manifest" "selfsigned_issuer" {
  depends_on = [time_sleep.wait_for_cert_manager]
  yaml_body = yamlencode({
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata   = { name = "selfsigned-issuer" }
    spec       = { selfSigned = {} }
  })
}

locals {
  cert_issuer_name = var.dns_zone_name != "" ? "letsencrypt-prod" : "selfsigned-issuer"
  cert_depends_on = var.dns_zone_name != "" ? [
    kubectl_manifest.letsencrypt_prod_issuer[0],
    kubernetes_namespace.teleport_cluster,
  ] : [kubectl_manifest.selfsigned_issuer, kubernetes_namespace.teleport_cluster]
}

resource "kubectl_manifest" "teleport_certificate" {
  depends_on = [
    kubectl_manifest.letsencrypt_prod_issuer,
    kubectl_manifest.selfsigned_issuer,
    kubernetes_namespace.teleport_cluster,
  ]
  yaml_body = yamlencode({
    apiVersion = "cert-manager.io/v1"
    kind       = "Certificate"
    metadata = {
      name      = "teleport-tls"
      namespace = kubernetes_namespace.teleport_cluster.metadata[0].name
    }
    spec = {
      secretName  = "teleport-tls"
      issuerRef   = { name = local.cert_issuer_name, kind = "ClusterIssuer" }
      dnsNames    = [var.proxy_address, "*.${var.proxy_address}"]
      duration    = "2160h"
      renewBefore = "720h"
    }
  })
}
