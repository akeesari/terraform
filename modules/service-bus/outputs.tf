output "id" {
  description = "Service Bus namespace resource ID."
  value       = azurerm_servicebus_namespace.this.id
}

output "name" {
  description = "Service Bus namespace name."
  value       = azurerm_servicebus_namespace.this.name
}

output "endpoint" {
  description = "Default Service Bus namespace endpoint (used by SDKs to connect via Entra identity)."
  value       = azurerm_servicebus_namespace.this.endpoint
}

output "queue_ids" {
  description = "Map of queue name → resource ID for all created queues."
  value       = { for k, v in azurerm_servicebus_queue.this : k => v.id }
}

output "topic_ids" {
  description = "Map of topic name → resource ID for all created topics."
  value       = { for k, v in azurerm_servicebus_topic.this : k => v.id }
}
