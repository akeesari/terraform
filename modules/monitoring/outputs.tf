output "id" {
  description = "Log Analytics Workspace resource ID."
  value       = try(azurerm_log_analytics_workspace.this[0].id, null)
}

output "name" {
  description = "Log Analytics Workspace name."
  value       = try(azurerm_log_analytics_workspace.this[0].name, null)
}

output "workspace_id" {
  description = "Log Analytics Workspace GUID — used in KQL queries and data export connections."
  value       = try(azurerm_log_analytics_workspace.this[0].workspace_id, null)
}

output "primary_shared_key" {
  description = "Primary shared key for direct agent connections (sensitive)."
  value       = try(azurerm_log_analytics_workspace.this[0].primary_shared_key, null)
  sensitive   = true
}

output "application_insights_id" {
  description = "Application Insights resource ID."
  value       = try(azurerm_application_insights.this[0].id, null)
}

output "application_insights_name" {
  description = "Application Insights resource name."
  value       = try(azurerm_application_insights.this[0].name, null)
}

output "instrumentation_key" {
  description = "Application Insights instrumentation key (sensitive)."
  value       = try(azurerm_application_insights.this[0].instrumentation_key, null)
  sensitive   = true
}

output "connection_string" {
  description = "Application Insights connection string (sensitive)."
  value       = try(azurerm_application_insights.this[0].connection_string, null)
  sensitive   = true
}

output "action_group_id" {
  description = "Monitor Action Group resource ID. Pass to postgres and other modules for metric alerts."
  value       = try(azurerm_monitor_action_group.this[0].id, null)
}

output "action_group_name" {
  description = "Monitor Action Group name."
  value       = try(azurerm_monitor_action_group.this[0].name, null)
}
