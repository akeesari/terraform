# =============================================================================
# otel-operator Module Variables
# =============================================================================

variable "chart_version" {
  description = "OpenTelemetry Operator Helm chart version"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace for OpenTelemetry Operator"
  type        = string
  default     = "opentelemetry-operator"
}

variable "schedule_on_system_nodes" {
  description = "Pin the operator pod to the system node pool"
  type        = bool
  default     = true
}
