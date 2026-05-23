output "id" {
  description = "Key Vault resource ID."
  value       = azurerm_key_vault.this.id
}

output "name" {
  description = "Key Vault name."
  value       = azurerm_key_vault.this.name
}

output "vault_uri" {
  description = "Key Vault URI (e.g. https://kv-myproject-dev.vault.azure.net/)."
  value       = azurerm_key_vault.this.vault_uri
}

output "private_endpoint_id" {
  description = "Private endpoint resource ID; null when enable_private_endpoints = false."
  value       = try(azurerm_private_endpoint.this[0].id, null)
}

output "postgres_cmk_id" {
  description = "PostgreSQL CMK key resource ID; null when enable_postgres_cmk = false."
  value       = try(azurerm_key_vault_key.postgres_cmk[0].id, null)
}

output "postgres_cmk_version_id" {
  description = "PostgreSQL CMK key version ID (versioned URL for server-level encryption config)."
  value       = try(azurerm_key_vault_key.postgres_cmk[0].versionless_id, null)
}

output "storage_cmk_id" {
  description = "Storage Account CMK key resource ID; null when enable_storage_cmk = false."
  value       = try(azurerm_key_vault_key.storage_cmk[0].id, null)
}

output "storage_cmk_version_id" {
  description = "Storage Account CMK key version ID."
  value       = try(azurerm_key_vault_key.storage_cmk[0].versionless_id, null)
}

output "tenant_id" {
  description = "Azure AD tenant ID of the Key Vault — useful for role assignment and Entra-scoped callers."
  value       = data.azurerm_client_config.current.tenant_id
}
