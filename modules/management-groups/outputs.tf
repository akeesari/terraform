output "id" {
  description = "Management group resource ID."
  value       = try(azurerm_management_group.this[0].id, null)
}

output "name" {
  description = "Management group name."
  value       = try(azurerm_management_group.this[0].name, null)
}
