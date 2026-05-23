output "id" {
  description = "Application Gateway resource ID."
  value       = azurerm_application_gateway.this.id
}

output "name" {
  description = "Application Gateway name."
  value       = azurerm_application_gateway.this.name
}

output "public_ip_id" {
  description = "Resource ID of the public IP associated with the Application Gateway."
  value       = azurerm_public_ip.this.id
}

output "public_ip_address" {
  description = "Public IP address of the Application Gateway frontend."
  value       = azurerm_public_ip.this.ip_address
}

output "nsg_id" {
  description = "Resource ID of the Application Gateway subnet NSG. Null when enable_nsg = false."
  value       = one(azurerm_network_security_group.this[*].id)
}

output "diagnostic_setting_id" {
  description = "Resource ID of the diagnostic setting. Null when enable_diagnostics = false."
  value       = one(azurerm_monitor_diagnostic_setting.this[*].id)
}

output "backend_address_pool_ids" {
  description = "Map of backend pool name → resource ID for all configured backend address pools."
  value       = { for pool in azurerm_application_gateway.this.backend_address_pool : pool.name => pool.id }
}

output "frontend_ip_config_name" {
  description = "Name of the frontend IP configuration block. Use this when wiring other resources (e.g. private endpoint) to the gateway."
  value       = "${var.name}-feip"
}
