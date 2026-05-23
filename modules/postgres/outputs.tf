output "id" {
  description = "PostgreSQL flexible server resource ID."
  value       = try(azurerm_postgresql_flexible_server.this[0].id, null)
}

output "name" {
  description = "PostgreSQL flexible server name."
  value       = try(azurerm_postgresql_flexible_server.this[0].name, null)
}

output "server_id" {
  description = "Deprecated: use id instead. PostgreSQL flexible server ID."
  value       = try(azurerm_postgresql_flexible_server.this[0].id, null)
}
output "fqdn" {
  description = "Fully qualified domain name of the PostgreSQL server"
  value       = try(azurerm_postgresql_flexible_server.this[0].fqdn, null)
}

output "database_names" {
  description = "Map of database names created on the server"
  value       = { for k, v in azurerm_postgresql_flexible_server_database.databases : k => v.name }
}

output "identity_principal_id" {
  description = "Principal ID of the PostgreSQL server managed identity (for CMK)"
  value       = var.enable_postgres_server ? try(azurerm_postgresql_flexible_server.this[0].identity[0].principal_id, null) : null
}
