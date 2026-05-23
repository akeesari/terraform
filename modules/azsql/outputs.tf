output "id" {
  description = "SQL Server resource ID."
  value       = try(azurerm_mssql_server.this[0].id, null)
}

output "name" {
  description = "SQL Server name."
  value       = try(azurerm_mssql_server.this[0].name, null)
}

output "fqdn" {
  description = "Fully qualified domain name of the SQL Server."
  value       = try(azurerm_mssql_server.this[0].fully_qualified_domain_name, null)
}

output "database_ids" {
  description = "Map of database names to their resource IDs."
  value       = { for k, v in azurerm_mssql_database.this : k => v.id }
}
