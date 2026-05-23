output "id" {
  description = "API Management service resource ID."
  value       = azurerm_api_management.this.id
}

output "name" {
  description = "API Management service name."
  value       = azurerm_api_management.this.name
}

output "gateway_url" {
  description = "Gateway URL — the public endpoint that API consumers call."
  value       = azurerm_api_management.this.gateway_url
}

output "developer_portal_url" {
  description = "Developer portal URL where API consumers can browse and test APIs."
  value       = azurerm_api_management.this.developer_portal_url
}

output "management_api_url" {
  description = "Management API URL for administrative REST calls."
  value       = azurerm_api_management.this.management_api_url
}

output "principal_id" {
  description = "System-assigned managed identity principal ID. Use to grant this APIM instance access to Key Vault certificates or backend resources."
  value       = azurerm_api_management.this.identity[0].principal_id
}

output "public_ip_addresses" {
  description = "Public IP addresses of the gateway. Useful for firewall allow-list rules on backend services."
  value       = azurerm_api_management.this.public_ip_addresses
}
