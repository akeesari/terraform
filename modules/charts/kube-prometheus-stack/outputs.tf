# =============================================================================
# kube-prometheus-stack Module Outputs
# =============================================================================

output "namespace" {
  description = "Namespace where kube-prometheus-stack is deployed"
  value       = var.enabled ? local.namespace : null
}

output "prometheus_service_url" {
  description = "Internal ClusterIP URL for Prometheus"
  value       = var.enabled ? "http://kube-prometheus-stack-prometheus.${var.namespace}.svc.cluster.local:9090" : null
}

output "alertmanager_service_url" {
  description = "Internal ClusterIP URL for Alertmanager"
  value       = var.enabled ? "http://kube-prometheus-stack-alertmanager.${var.namespace}.svc.cluster.local:9093" : null
}
