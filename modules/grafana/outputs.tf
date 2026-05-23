output "id" {
  description = "Managed Grafana workspace resource ID."
  value       = azurerm_dashboard_grafana.this.id
}

output "name" {
  description = "Managed Grafana workspace name."
  value       = azurerm_dashboard_grafana.this.name
}

output "endpoint" {
  description = "Grafana workspace endpoint URL."
  value       = azurerm_dashboard_grafana.this.endpoint
}

output "principal_id" {
  description = "Object ID of the Grafana workspace's system-assigned managed identity."
  value       = azurerm_dashboard_grafana.this.identity[0].principal_id
}

output "grafana_version" {
  description = "Full Grafana version string deployed (e.g. 10.0.0)."
  value       = azurerm_dashboard_grafana.this.grafana_version
}
