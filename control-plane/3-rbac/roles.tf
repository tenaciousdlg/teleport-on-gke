resource "kubectl_manifest" "role_base_user" {
  yaml_body = yamlencode({
    apiVersion = "resources.teleport.dev/v1"
    kind       = "TeleportRoleV7"
    metadata = {
      name      = "base-user"
      namespace = data.kubernetes_namespace.teleport_cluster.metadata[0].name
    }
    spec = {
      allow = {
        rules = [
          { resources = ["event"], verbs = ["list", "read"] },
          { resources = ["session"], verbs = ["read", "list"] }
        ]
      }
      options = {
        max_session_ttl = "8h0m0s"
      }
    }
  })
}

# dev: full read/write access to env:dev resources; can request prod-readonly
resource "kubectl_manifest" "role_dev" {
  yaml_body = yamlencode({
    apiVersion = "resources.teleport.dev/v1"
    kind       = "TeleportRoleV7"
    metadata = {
      name      = "dev"
      namespace = data.kubernetes_namespace.teleport_cluster.metadata[0].name
    }
    spec = {
      allow = {
        kubernetes_labels = { env = ["dev"] }
        kubernetes_groups = ["dev", "system:authenticated"]
        kubernetes_resources = [
          { kind = "*", name = "*", namespace = "*", verbs = ["*"] }
        ]
        node_labels = { env = ["dev"] }
        logins      = ["{{email.local(external.email)}}", "ubuntu"]
        request = {
          roles      = ["prod-readonly"]
          thresholds = [{ approve = 1, deny = 1 }]
        }
        rules = [
          { resources = ["event"], verbs = ["list", "read"] },
          { resources = ["session"], verbs = ["read", "list"] }
        ]
      }
      options = {
        create_host_user_mode          = "keep"
        create_host_user_default_shell = "/bin/bash"
        max_session_ttl                = "8h0m0s"
        enhanced_recording             = ["command", "network"]
      }
    }
  })
}

# prod-readonly: read-only access to env:prod kubernetes resources
# Standing access for engineers; requestable (with approval) by devs
resource "kubectl_manifest" "role_prod_readonly" {
  yaml_body = yamlencode({
    apiVersion = "resources.teleport.dev/v1"
    kind       = "TeleportRoleV7"
    metadata = {
      name      = "prod-readonly"
      namespace = data.kubernetes_namespace.teleport_cluster.metadata[0].name
    }
    spec = {
      allow = {
        kubernetes_labels = { env = ["prod"] }
        kubernetes_groups = ["viewers"]
        kubernetes_resources = [
          { kind = "*", name = "*", namespace = "*", verbs = ["get", "list", "watch"] }
        ]
        rules = [
          { resources = ["event"], verbs = ["list", "read"] },
          { resources = ["session"], verbs = ["read", "list"] }
        ]
      }
      options = {
        max_session_ttl = "8h0m0s"
      }
    }
  })
}

# prod-access: full read/write access to env:prod resources
# Requestable (with peer approval) by engineers; not granted standing to anyone
resource "kubectl_manifest" "role_prod_access" {
  yaml_body = yamlencode({
    apiVersion = "resources.teleport.dev/v1"
    kind       = "TeleportRoleV7"
    metadata = {
      name      = "prod-access"
      namespace = data.kubernetes_namespace.teleport_cluster.metadata[0].name
    }
    spec = {
      allow = {
        kubernetes_labels = { env = ["prod"] }
        kubernetes_groups = ["dev", "system:authenticated"]
        kubernetes_resources = [
          { kind = "*", name = "*", namespace = "*", verbs = ["*"] }
        ]
        node_labels = { env = ["prod"] }
        logins      = ["{{email.local(external.email)}}", "ubuntu"]
        rules = [
          { resources = ["event"], verbs = ["list", "read"] },
          { resources = ["session"], verbs = ["read", "list"] }
        ]
      }
      options = {
        create_host_user_mode          = "keep"
        create_host_user_default_shell = "/bin/bash"
        max_session_ttl                = "4h0m0s"
        enhanced_recording             = ["command", "network"]
      }
    }
  })
}

# engineer: meta-role that adds review and escalation capabilities
# Grants no direct resource access — that comes from dev + prod-readonly via the access list
# Engineers can: approve dev requests for prod-readonly; approve peer requests for prod-access; request prod-access themselves
resource "kubectl_manifest" "role_engineer" {
  yaml_body = yamlencode({
    apiVersion = "resources.teleport.dev/v1"
    kind       = "TeleportRoleV7"
    metadata = {
      name      = "engineer"
      namespace = data.kubernetes_namespace.teleport_cluster.metadata[0].name
    }
    spec = {
      allow = {
        review_requests = {
          roles            = ["prod-readonly", "prod-access"]
          preview_as_roles = ["prod-readonly", "prod-access"]
        }
        request = {
          roles      = ["prod-access"]
          thresholds = [{ approve = 1, deny = 1 }]
        }
        rules = [
          { resources = ["event"], verbs = ["list", "read"] },
          { resources = ["session"], verbs = ["read", "list"] }
        ]
      }
      options = {
        max_session_ttl = "8h0m0s"
      }
    }
  })
}

# devs: standing dev environment access + can request prod-readonly
resource "kubectl_manifest" "access_list_devs" {
  depends_on = [kubectl_manifest.role_dev, kubectl_manifest.role_base_user]
  yaml_body = yamlencode({
    apiVersion = "resources.teleport.dev/v1"
    kind       = "TeleportAccessList"
    metadata = {
      name      = "devs"
      namespace = data.kubernetes_namespace.teleport_cluster.metadata[0].name
    }
    spec = {
      title       = "Devs"
      description = "Dev team: full env:dev access, can request prod-readonly with engineer approval"
      type        = "static"
      owners      = [{ name = var.access_list_owner, description = "Platform admin" }]
      grants      = { roles = ["dev", "base-user"] }
    }
  })
}

# engineers: standing dev + prod-readonly access; can approve dev requests; can request prod-access
resource "kubectl_manifest" "access_list_engineers" {
  depends_on = [
    kubectl_manifest.role_dev,
    kubectl_manifest.role_prod_readonly,
    kubectl_manifest.role_engineer,
    kubectl_manifest.role_base_user,
  ]
  yaml_body = yamlencode({
    apiVersion = "resources.teleport.dev/v1"
    kind       = "TeleportAccessList"
    metadata = {
      name      = "engineers"
      namespace = data.kubernetes_namespace.teleport_cluster.metadata[0].name
    }
    spec = {
      title       = "Engineers"
      description = "Engineering team: full env:dev + standing prod-readonly; approve dev requests; request prod-access"
      type        = "static"
      owners      = [{ name = var.access_list_owner, description = "Platform admin" }]
      grants      = { roles = ["dev", "prod-readonly", "engineer", "base-user"] }
    }
  })
}

resource "kubectl_manifest" "autoupdate_config" {
  yaml_body = yamlencode({
    apiVersion = "resources.teleport.dev/v1"
    kind       = "TeleportAutoupdateConfigV1"
    metadata = {
      name      = "autoupdate-config"
      namespace = data.kubernetes_namespace.teleport_cluster.metadata[0].name
    }
    spec = {
      agents = {
        mode     = var.autoupdate_mode
        strategy = "halt-on-error"
        schedules = {
          regular = [
            {
              name       = "default"
              days       = ["Mon", "Tue", "Wed", "Thu", "Fri"]
              start_hour = 2
            }
          ]
        }
      }
    }
  })
}
