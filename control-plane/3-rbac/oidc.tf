resource "kubectl_manifest" "oidc_connector_google" {
  yaml_body = yamlencode({
    apiVersion = "resources.teleport.dev/v3"
    kind       = "TeleportOIDCConnector"
    metadata = {
      name      = "google"
      namespace = data.kubernetes_namespace.teleport_cluster.metadata[0].name
    }
    spec = {
      issuer_url    = "https://accounts.google.com"
      client_id     = var.oidc_client_id
      client_secret = var.oidc_client_secret
      redirect_url  = ["https://${var.proxy_address}/v1/webapi/oidc/callback"]
      display       = "Google"
      scope         = ["openid", "email", "profile"]
      claims_to_roles = [
        { claim = "email", value = "*@${var.google_domain}", roles = ["base-user"] }
      ]
      username_claim = "email"
      email_claim    = "email"
    }
  })
}

