# =============================================================================
# Grafana Loki Module Outputs
# =============================================================================

output "namespace" {
  description = "Kubernetes namespace where Loki stack is deployed."
  value       = var.enabled ? kubernetes_namespace.monitoring[0].metadata[0].name : null
}

output "grafana_url" {
  description = "Grafana dashboard HTTPS URL."
  value       = var.enabled && var.grafana_host != "" ? "https://${var.grafana_host}" : null
}

output "loki_endpoint" {
  description = "Loki push endpoint (internal cluster URL)."
  value       = var.enabled ? "http://loki.monitoring.svc.cluster.local:3100" : null
}
