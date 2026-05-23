# =============================================================================
# otel-collector Module Outputs
# =============================================================================

output "namespace" {
  description = "Namespace where OpenTelemetry Collector is deployed"
  value       = kubernetes_namespace.otel_collector.metadata[0].name
}

output "chart_version" {
  description = "OpenTelemetry Collector chart version deployed"
  value       = helm_release.otel_collector.version
}

output "otlp_http_endpoint" {
  description = "OTLP HTTP endpoint (cluster internal)"
  value       = "http://opentelemetry-collector.${var.namespace}.svc.cluster.local:4318"
}

output "otlp_grpc_endpoint" {
  description = "OTLP gRPC endpoint (cluster internal)"
  value       = "http://opentelemetry-collector.${var.namespace}.svc.cluster.local:4317"
}
