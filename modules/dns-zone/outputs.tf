output "id" {
  description = "DNS zone resource ID (public or private)."
  value = var.enable_dns_zone ? (
    local.is_public
    ? azurerm_dns_zone.this[0].id
    : azurerm_private_dns_zone.this[0].id
  ) : null
}

output "name" {
  description = "DNS zone name."
  value = var.enable_dns_zone ? (
    local.is_public
    ? azurerm_dns_zone.this[0].name
    : azurerm_private_dns_zone.this[0].name
  ) : null
}

output "resource_group_name" {
  description = "Resource group containing the DNS zone."
  value = var.enable_dns_zone ? (
    local.is_public
    ? azurerm_dns_zone.this[0].resource_group_name
    : azurerm_private_dns_zone.this[0].resource_group_name
  ) : null
}

output "name_servers" {
  description = "Authoritative name servers assigned to this zone. Empty list for private zones."
  value       = var.enable_dns_zone && local.is_public ? azurerm_dns_zone.this[0].name_servers : []
}

output "vnet_link_ids" {
  description = "Map of virtual network link IDs keyed by link name. Empty map for public zones."
  value       = { for k, v in azurerm_private_dns_zone_virtual_network_link.this : k => v.id }
}
