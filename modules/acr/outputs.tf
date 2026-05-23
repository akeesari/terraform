output "id" {
  description = "Azure Container Registry resource ID."
  value       = try(azurerm_container_registry.this[0].id, null)
}

output "name" {
  description = "Azure Container Registry name."
  value       = try(azurerm_container_registry.this[0].name, null)
}

output "login_server" {
  description = "ACR login server hostname (e.g. myregistry.azurecr.io)."
  value       = try(azurerm_container_registry.this[0].login_server, null)
}
