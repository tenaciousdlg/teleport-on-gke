locals {
  member_pairs = flatten([
    for list_name, members in var.access_list_members : [
      for member in members : {
        key         = "${list_name}/${member}"
        access_list = list_name
        member      = member
      }
    ]
  ])
}

resource "teleport_access_list_member" "members" {
  for_each = { for m in local.member_pairs : m.key => m }

  header = {
    metadata = {
      name = each.value.member
    }
    version = "v1"
  }
  spec = {
    access_list     = each.value.access_list
    membership_kind = 1
  }
}
