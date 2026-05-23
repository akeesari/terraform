output "id" {
  description = "Function App resource ID."
  value       = azurerm_linux_function_app.this.id
}

output "name" {
  description = "Function App name."
  value       = azurerm_linux_function_app.this.name
}

output "default_hostname" {
  description = "Default hostname for the Function App (e.g. my-func.azurewebsites.net)."
  value       = azurerm_linux_function_app.this.default_hostname
}

output "principal_id" {
  description = "System-assigned managed identity principal ID. Use to grant this function app access to other Azure resources."
  value       = azurerm_linux_function_app.this.identity[0].principal_id
}

output "service_plan_id" {
  description = "Service Plan resource ID. Can be shared across multiple function apps in the same stack."
  value       = azurerm_service_plan.this.id
}

output "storage_account_id" {
  description = "Backing storage account resource ID."
  value       = azurerm_storage_account.this.id
}
