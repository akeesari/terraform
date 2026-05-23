output "id" {
  description = "Container Apps Environment resource ID."
  value       = azurerm_container_app_environment.this.id
}

output "name" {
  description = "Container Apps Environment name."
  value       = azurerm_container_app_environment.this.name
}

output "default_domain" {
  description = "Default domain suffix for all apps in this environment (e.g. <hash>.<region>.azurecontainerapps.io)."
  value       = azurerm_container_app_environment.this.default_domain
}

output "app_ids" {
  description = "Map of Container App name → resource ID."
  value       = { for k, v in azurerm_container_app.this : k => v.id }
}

output "app_urls" {
  description = "Map of Container App name → latest revision FQDN. Empty string for apps with no ingress."
  value       = { for k, v in azurerm_container_app.this : k => try(v.latest_revision_fqdn, "") }
}

output "app_principal_ids" {
  description = "Map of Container App name → system-assigned managed identity principal ID. Use to assign roles (e.g. ACR pull, Key Vault reader)."
  value       = { for k, v in azurerm_container_app.this : k => v.identity[0].principal_id }
}
