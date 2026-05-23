output "id" {
  description = "Bastion host resource ID."
  value       = azurerm_bastion_host.this.id
}

output "name" {
  description = "Bastion host name."
  value       = azurerm_bastion_host.this.name
}

output "public_ip_id" {
  description = "Public IP resource ID attached to the Bastion host."
  value       = azurerm_public_ip.this.id
}

output "public_ip_address" {
  description = "Public IP address of the Bastion host."
  value       = azurerm_public_ip.this.ip_address
}

output "dns_name" {
  description = "Fully qualified DNS name of the Bastion host."
  value       = azurerm_bastion_host.this.dns_name
}
