# =============================================================================
# blackbox-exporter Module Outputs
# =============================================================================

output "namespace" {
  description = "Kubernetes namespace where blackbox-exporter is deployed"
  value       = var.enabled ? kubernetes_namespace.blackbox[0].metadata[0].name : null
}

output "service_url" {
  description = "Internal ClusterIP URL for blackbox-exporter /probe endpoint"
  value       = var.enabled ? "http://blackbox-exporter-prometheus-blackbox-exporter.${var.namespace}.svc.cluster.local:9115/probe" : null
}
