output "id" {
  description = "Event Hub namespace resource ID."
  value       = azurerm_eventhub_namespace.this.id
}

output "name" {
  description = "Event Hub namespace name."
  value       = azurerm_eventhub_namespace.this.name
}

output "hub_ids" {
  description = "Map of Event Hub name → resource ID."
  value       = { for k, v in azurerm_eventhub.this : k => v.id }
}

output "consumer_group_ids" {
  description = "Map of 'hub/group' key → resource ID for all created consumer groups."
  value       = { for k, v in azurerm_eventhub_consumer_group.this : k => v.id }
}
