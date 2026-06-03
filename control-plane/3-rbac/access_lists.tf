# devs: standing dev environment access + can request prod-readonly
resource "teleport_access_list" "devs" {
  depends_on = [teleport_role.dev, teleport_role.base_user]

  header = {
    metadata = { name = "devs" }
    version  = "v1"
  }
  spec = {
    title       = "Devs"
    description = "Dev team: full env:dev access, can request prod-readonly with engineer approval"
    type        = "static"
    owners      = [{ name = var.access_list_owner, description = "Platform admin" }]
    grants      = { roles = ["dev", "base-user"] }
  }
}

# engineers: standing dev + prod-readonly; can approve dev requests; can request prod-access
resource "teleport_access_list" "engineers" {
  depends_on = [teleport_role.dev, teleport_role.prod_readonly, teleport_role.engineer, teleport_role.base_user]

  header = {
    metadata = { name = "engineers" }
    version  = "v1"
  }
  spec = {
    title       = "Engineers"
    description = "Engineering team: full env:dev + standing prod-readonly; approve dev requests; request prod-access"
    type        = "static"
    owners      = [{ name = var.access_list_owner, description = "Platform admin" }]
    grants      = { roles = ["dev", "prod-readonly", "engineer", "base-user"] }
  }
}
