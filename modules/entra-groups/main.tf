resource "azuread_group" "this" {
  for_each = var.enable ? { for g in var.groups : g.name => g } : {}

  display_name     = each.value.display_name
  description      = try(each.value.description, null)
  mail_enabled     = try(each.value.mail_enabled, false)
  mail_nickname    = try(each.value.mail_nickname, each.value.name)
  security_enabled = true
  types            = try(each.value.mail_enabled, false) ? ["Unified"] : []

  assignable_to_role = try(each.value.assignable_to_role, false)

  members = try(each.value.member_object_ids, [])
  owners  = try(each.value.owner_object_ids, [])

  lifecycle {
    ignore_changes = [members, owners]
  }
}
