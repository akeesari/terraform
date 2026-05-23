output "virtual_network_id" {
  description = "Resource ID of the Virtual Network."
  value       = azurerm_virtual_network.this.id
}

output "virtual_network_name" {
  description = "Name of the Virtual Network."
  value       = azurerm_virtual_network.this.name
}

output "subnet_ids" {
  description = "Map of subnet name to subnet resource ID."
  value       = { for k, v in azurerm_subnet.this : k => v.id }
}

output "nsg_ids" {
  description = "Map of subnet name to NSG resource ID."
  value       = { for k, v in azurerm_network_security_group.subnet : k => v.id }
}

output "route_table_ids" {
  description = "Map of subnet name to route table resource ID (only for subnets with a route_table defined)."
  value       = { for k, v in azurerm_route_table.subnet : k => v.id }
}
