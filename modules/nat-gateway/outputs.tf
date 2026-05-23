output "id" {
  description = "NAT Gateway resource ID."
  value       = try(azurerm_nat_gateway.this[0].id, null)
}

output "name" {
  description = "NAT Gateway name."
  value       = try(azurerm_nat_gateway.this[0].name, null)
}

output "public_ip_prefix_id" {
  description = "Public IP prefix resource ID attached to the NAT Gateway."
  value       = try(azurerm_public_ip_prefix.this[0].id, null)
}

output "public_ip_prefix_cidr" {
  description = "Public IP prefix CIDR block (e.g. 20.10.1.0/31). Allow-list this in downstream firewalls."
  value       = try(azurerm_public_ip_prefix.this[0].ip_prefix, null)
}
