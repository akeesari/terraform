# =============================================================================
# otel-collector Module Variables
# =============================================================================

variable "chart_version" {
  description = "OpenTelemetry Collector Helm chart version"
  type        = string
}

variable "cluster_name" {
  description = "AKS cluster name (used to construct KV secret name)"
  type        = string
}

variable "aks_keyvault_name" {
  description = "Name of the cluster Key Vault"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group containing the Key Vault"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace for OpenTelemetry Collector"
  type        = string
  default     = "opentelemetry-collector"
}

variable "schedule_on_system_nodes" {
  description = "Pin the collector pod to the system node pool"
  type        = bool
  default     = true
}
