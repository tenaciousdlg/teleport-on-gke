data "kubernetes_service" "teleport_cluster" {
  depends_on = [helm_release.teleport_cluster]
  metadata {
    name      = helm_release.teleport_cluster.name
    namespace = helm_release.teleport_cluster.namespace
  }
}

resource "google_dns_record_set" "cluster_endpoint" {
  count        = var.dns_zone_name != "" ? 1 : 0
  name         = "${var.proxy_address}."
  managed_zone = var.dns_zone_name
  type         = "A"
  ttl          = 60
  rrdatas      = [data.kubernetes_service.teleport_cluster.status[0].load_balancer[0].ingress[0].ip]
}

resource "google_dns_record_set" "wild_cluster_endpoint" {
  count        = var.dns_zone_name != "" ? 1 : 0
  name         = "*.${var.proxy_address}."
  managed_zone = var.dns_zone_name
  type         = "A"
  ttl          = 60
  rrdatas      = [data.kubernetes_service.teleport_cluster.status[0].load_balancer[0].ingress[0].ip]
}
