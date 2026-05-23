output "id" {
  description = "Azure OpenAI resource ID."
  value       = azurerm_cognitive_account.this.id
}

output "name" {
  description = "Azure OpenAI account name."
  value       = azurerm_cognitive_account.this.name
}

output "endpoint" {
  description = "Azure OpenAI REST endpoint URL (e.g. https://oai-myapp-dev.openai.azure.com/)."
  value       = azurerm_cognitive_account.this.endpoint
}

output "primary_access_key" {
  description = "Primary access key for Azure OpenAI. Only populated when local_auth_enabled = true. Store in Key Vault; do not log."
  value       = var.local_auth_enabled ? azurerm_cognitive_account.this.primary_access_key : null
  sensitive   = true
}
