output "id" {
  description = "Private endpoint resource ID."
  value       = azurerm_private_endpoint.this.id
}

output "name" {
  description = "Private endpoint resource name."
  value       = azurerm_private_endpoint.this.name
}

output "private_ip_address" {
  description = "Private IP address assigned to the private endpoint NIC."
  value       = try(azurerm_private_endpoint.this.private_service_connection[0].private_ip_address, null)
}

output "private_dns_zone_id" {
  description = "Resource ID of the private DNS zone."
  value       = azurerm_private_dns_zone.this.id
}

output "private_dns_zone_name" {
  description = "Name of the private DNS zone (e.g. 'privatelink.redis.cache.windows.net')."
  value       = azurerm_private_dns_zone.this.name
}
