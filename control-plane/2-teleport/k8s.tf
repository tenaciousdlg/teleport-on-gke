resource "kubernetes_namespace" "teleport_cluster" {
  metadata {
    name = "teleport-cluster"
    labels = {
      "pod-security.kubernetes.io/enforce" = "baseline"
    }
  }
}

resource "kubernetes_service_account" "teleport_auth" {
  metadata {
    name      = "teleport-cluster"
    namespace = kubernetes_namespace.teleport_cluster.metadata[0].name
    annotations = {
      "iam.gke.io/gcp-service-account" = google_service_account.teleport.email
    }
  }
}

resource "kubernetes_service_account" "teleport_proxy" {
  metadata {
    name      = "teleport-cluster-proxy"
    namespace = kubernetes_namespace.teleport_cluster.metadata[0].name
    annotations = {
      "iam.gke.io/gcp-service-account" = google_service_account.teleport.email
    }
  }
}

resource "kubernetes_service_account" "teleport_operator" {
  metadata {
    name      = "teleport-cluster-operator"
    namespace = kubernetes_namespace.teleport_cluster.metadata[0].name
  }
}

# Helm's operator Role template omits TeleportAutoupdateConfigV1/VersionV1 — add them via a supplemental Role.
resource "kubernetes_role" "teleport_operator_autoupdate" {
  metadata {
    name      = "teleport-cluster-operator-autoupdate"
    namespace = kubernetes_namespace.teleport_cluster.metadata[0].name
  }
  rule {
    api_groups = ["resources.teleport.dev"]
    resources  = ["teleportautoupdateconfigsv1", "teleportautoupdateversionsv1"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }
}

resource "kubernetes_role_binding" "teleport_operator_autoupdate" {
  metadata {
    name      = "teleport-cluster-operator-autoupdate"
    namespace = kubernetes_namespace.teleport_cluster.metadata[0].name
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.teleport_operator_autoupdate.metadata[0].name
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.teleport_operator.metadata[0].name
    namespace = kubernetes_namespace.teleport_cluster.metadata[0].name
  }
}

resource "kubernetes_secret" "license" {
  count = var.license_pem != "" ? 1 : 0

  metadata {
    name      = "license"
    namespace = kubernetes_namespace.teleport_cluster.metadata[0].name
  }
  data = {
    "license.pem" = var.license_pem
  }
  type = "Opaque"
}
