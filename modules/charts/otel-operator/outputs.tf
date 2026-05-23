# =============================================================================
# otel-operator Module Outputs
# =============================================================================

output "namespace" {
  description = "Namespace where OpenTelemetry Operator is deployed"
  value       = kubernetes_namespace.otel_operator.metadata[0].name
}

output "chart_version" {
  description = "OpenTelemetry Operator chart version deployed"
  value       = helm_release.otel_operator.version
}
