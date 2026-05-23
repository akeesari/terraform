output "id" {
  description = "Cosmos DB account resource ID."
  value       = azurerm_cosmosdb_account.this.id
}

output "name" {
  description = "Cosmos DB account name."
  value       = azurerm_cosmosdb_account.this.name
}

output "endpoint" {
  description = "Cosmos DB SQL endpoint URI."
  value       = azurerm_cosmosdb_account.this.endpoint
}

output "primary_key" {
  description = "Cosmos DB primary master key. Only valid when local_authentication_disabled = false."
  value       = azurerm_cosmosdb_account.this.primary_key
  sensitive   = true
}

output "secondary_key" {
  description = "Cosmos DB secondary master key. Only valid when local_authentication_disabled = false."
  value       = azurerm_cosmosdb_account.this.secondary_key
  sensitive   = true
}

output "primary_readonly_key" {
  description = "Cosmos DB primary read-only key. Only valid when local_authentication_disabled = false."
  value       = azurerm_cosmosdb_account.this.primary_readonly_key
  sensitive   = true
}

output "connection_strings" {
  description = "List of Cosmos DB connection strings."
  value       = azurerm_cosmosdb_account.this.connection_strings
  sensitive   = true
}

output "database_ids" {
  description = "Map of SQL database names to their resource IDs."
  value       = { for k, v in azurerm_cosmosdb_sql_database.this : k => v.id }
}

output "container_ids" {
  description = "Map of 'database/container' keys to SQL container resource IDs."
  value       = { for k, v in azurerm_cosmosdb_sql_container.this : k => v.id }
}

output "identity_principal_id" {
  description = "Principal ID of the system-assigned managed identity. Null when no identity is configured."
  value       = try(azurerm_cosmosdb_account.this.identity[0].principal_id, null)
}

output "private_endpoint_id" {
  description = "Private endpoint resource ID. Null when private endpoints are not enabled."
  value       = one(azurerm_private_endpoint.this[*].id)
}

output "diagnostic_setting_id" {
  description = "Diagnostic setting resource ID. Null when diagnostic settings are not enabled."
  value       = one(azurerm_monitor_diagnostic_setting.this[*].id)
}
