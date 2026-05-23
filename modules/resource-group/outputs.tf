output "id" {
  description = "Resource Group resource ID."
  value       = azurerm_resource_group.this.id
}

output "name" {
  description = "Resource Group name."
  value       = azurerm_resource_group.this.name
}

output "location" {
  description = "Azure region where the Resource Group resides."
  value       = azurerm_resource_group.this.location
}

output "tags" {
  description = "Merged tags applied to the Resource Group."
  value       = azurerm_resource_group.this.tags
}

output "lock_id" {
  description = "Management lock resource ID; null when enable_lock = false."
  value       = try(azurerm_management_lock.this[0].id, null)
}
