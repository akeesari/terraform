output "id" {
  description = "Storage account resource ID."
  value       = one(azurerm_storage_account.this[*].id)
}

output "name" {
  description = "Storage account name."
  value       = one(azurerm_storage_account.this[*].name)
}

output "primary_blob_endpoint" {
  description = "Primary blob endpoint URL."
  value       = one(azurerm_storage_account.this[*].primary_blob_endpoint)
}

output "primary_access_key" {
  description = "Primary storage account access key."
  value       = one(azurerm_storage_account.this[*].primary_access_key)
  sensitive   = true
}

output "container_names" {
  description = "Map of container name → container name for all created blob containers."
  value       = { for k, v in azurerm_storage_container.this : k => v.name }
}

output "queue_names" {
  description = "Map of queue name → queue name for all created storage queues."
  value       = { for k, v in azurerm_storage_queue.this : k => v.name }
}
