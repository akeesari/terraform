output "id" {
  description = "Application Insights resource ID."
  value       = try(azurerm_application_insights.this[0].id, null)
}

output "name" {
  description = "Application Insights resource name."
  value       = try(azurerm_application_insights.this[0].name, null)
}

output "app_id" {
  description = "Application Insights app ID (GUID)."
  value       = try(azurerm_application_insights.this[0].app_id, null)
}

output "instrumentation_key" {
  description = "Application Insights instrumentation key."
  value       = try(azurerm_application_insights.this[0].instrumentation_key, null)
  sensitive   = true
}

output "connection_string" {
  description = "Application Insights connection string."
  value       = try(azurerm_application_insights.this[0].connection_string, null)
  sensitive   = true
}
