resource "azurerm_role_assignment" "this" {
  for_each = var.enable ? {
    for r in var.role_assignments : "${r.scope}__${r.role_definition_name}__${r.principal_id}" => r
  } : {}

  scope                = each.value.scope
  role_definition_name = each.value.role_definition_name
  principal_id         = each.value.principal_id

  skip_service_principal_aad_check = try(each.value.skip_service_principal_aad_check, false)

  condition         = try(each.value.condition, null)
  condition_version = try(each.value.condition, null) != null ? "2.0" : null
}
