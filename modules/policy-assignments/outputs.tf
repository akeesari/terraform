output "id" {
  description = "Policy module identifier (placeholder for module convention)."
  value       = null
}

output "name" {
  description = "Policy module name (placeholder for module convention)."
  value       = "policy"
}

output "policy_assignment_ids" {
  description = "Map of policy assignment resource IDs."
  value = var.enable_policy ? {
    mcsb                 = azurerm_subscription_policy_assignment.mcsb[0].id
    allowed_locations    = azurerm_subscription_policy_assignment.allowed_locations[0].id
    allowed_locations_rg = azurerm_subscription_policy_assignment.allowed_locations_rg[0].id
    require_env_tag      = azurerm_subscription_policy_assignment.require_env_tag[0].id
    require_team_tag     = azurerm_subscription_policy_assignment.require_team_tag[0].id
    inherit_env_tag      = azurerm_subscription_policy_assignment.inherit_env_tag[0].id
    inherit_team_tag     = azurerm_subscription_policy_assignment.inherit_team_tag[0].id
    activity_log_diag    = azurerm_subscription_policy_assignment.activity_log_diag[0].id
  } : {}
}
