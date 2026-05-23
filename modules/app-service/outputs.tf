output "id" {
  description = "App Service Plan resource ID."
  value       = try(azurerm_service_plan.this[0].id, null)
}

output "name" {
  description = "App Service Plan name."
  value       = try(azurerm_service_plan.this[0].name, null)
}

output "web_app_hostname" {
  description = "Default hostname of the primary Linux web app."
  value       = try(azurerm_linux_web_app.app[0].default_hostname, null)
}

output "api_app_hostname" {
  description = "Default hostname of the secondary Linux API app."
  value       = try(azurerm_linux_web_app.api[0].default_hostname, null)
}

output "web_app_id" {
  description = "Resource ID of the primary Linux web app."
  value       = try(azurerm_linux_web_app.app[0].id, null)
}

output "api_app_id" {
  description = "Resource ID of the secondary Linux API app."
  value       = try(azurerm_linux_web_app.api[0].id, null)
}

output "app_insights_id" {
  description = "Application Insights resource ID."
  value       = try(azurerm_application_insights.this[0].id, null)
}

output "app_insights_instrumentation_key" {
  description = "Application Insights instrumentation key."
  value       = try(azurerm_application_insights.this[0].instrumentation_key, null)
  sensitive   = true
}

output "app_insights_connection_string" {
  description = "Application Insights connection string."
  value       = try(azurerm_application_insights.this[0].connection_string, null)
  sensitive   = true
}
