resource "teleport_oidc_connector" "google" {
  version = "v3"
  metadata = {
    name = "google"
  }
  spec = {
    client_id     = var.oidc_client_id
    client_secret = var.oidc_client_secret
    redirect_url  = ["https://${var.proxy_address}/v1/webapi/oidc/callback"]
    display       = "Google"
    scope         = ["openid", "email", "profile"]
    claims_to_roles = [
      {
        claim = "email"
        value = "*@${var.google_domain}"
        roles = ["base-user"]
      }
    ]
    username_claim = "email"
  }
}
