resource "teleport_role" "base_user" {
  version = "v7"
  metadata = {
    name = "base-user"
  }
  spec = {
    allow = {
      rules = [
        { resources = ["event"], verbs = ["list", "read"] },
        { resources = ["session"], verbs = ["read", "list"] },
      ]
    }
    options = {
      max_session_ttl = "8h0m0s"
    }
  }
}

# dev: full read/write access to env:dev resources; can request prod-readonly
resource "teleport_role" "dev" {
  version = "v7"
  metadata = {
    name = "dev"
  }
  spec = {
    allow = {
      kubernetes_labels    = { env = ["dev"] }
      kubernetes_groups    = ["dev", "system:authenticated"]
      kubernetes_resources = [{ kind = "*", name = "*", namespace = "*", verbs = ["*"] }]
      node_labels          = { env = ["dev"] }
      logins               = ["{{email.local(external.email)}}", "ubuntu"]
      request = {
        roles      = ["prod-readonly"]
        thresholds = [{ approve = 1, deny = 1 }]
      }
      rules = [
        { resources = ["event"], verbs = ["list", "read"] },
        { resources = ["session"], verbs = ["read", "list"] },
      ]
    }
    options = {
      max_session_ttl = "8h0m0s"
    }
  }
}

# prod-readonly: read-only access to env:prod kubernetes resources
# Standing for engineers; requestable (with approval) by devs
resource "teleport_role" "prod_readonly" {
  version = "v7"
  metadata = {
    name = "prod-readonly"
  }
  spec = {
    allow = {
      kubernetes_labels    = { env = ["prod"] }
      kubernetes_groups    = ["viewers"]
      kubernetes_resources = [{ kind = "*", name = "*", namespace = "*", verbs = ["get", "list", "watch"] }]
      rules = [
        { resources = ["event"], verbs = ["list", "read"] },
        { resources = ["session"], verbs = ["read", "list"] },
      ]
    }
    options = {
      max_session_ttl = "8h0m0s"
    }
  }
}

# prod-access: full read/write access to env:prod resources
# Requestable (with peer approval) by engineers; no one holds this standing
resource "teleport_role" "prod_access" {
  version = "v7"
  metadata = {
    name = "prod-access"
  }
  spec = {
    allow = {
      kubernetes_labels    = { env = ["prod"] }
      kubernetes_groups    = ["dev", "system:authenticated"]
      kubernetes_resources = [{ kind = "*", name = "*", namespace = "*", verbs = ["*"] }]
      node_labels          = { env = ["prod"] }
      logins               = ["{{email.local(external.email)}}", "ubuntu"]
      rules = [
        { resources = ["event"], verbs = ["list", "read"] },
        { resources = ["session"], verbs = ["read", "list"] },
      ]
    }
    options = {
      max_session_ttl = "4h0m0s"
    }
  }
}

# engineer: meta-role — no direct resource access
# Grants ability to review prod-readonly and prod-access requests, and request prod-access
resource "teleport_role" "engineer" {
  version = "v7"
  metadata = {
    name = "engineer"
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
        { resources = ["session"], verbs = ["read", "list"] },
      ]
    }
    options = {
      max_session_ttl = "8h0m0s"
    }
  }
}
