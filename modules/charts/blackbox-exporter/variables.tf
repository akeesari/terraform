# =============================================================================
# blackbox-exporter Module Variables
# =============================================================================

variable "enabled" {
  description = "Enable blackbox-exporter deployment"
  type        = bool
  default     = false
}

variable "chart_version" {
  description = "prometheus-blackbox-exporter Helm chart version"
  type        = string
  default     = "9.0.0"
}

variable "namespace" {
  description = "Kubernetes namespace for blackbox-exporter (dedicated 'blackbox' namespace)"
  type        = string
  default     = "blackbox"
}

variable "target_urls" {
  description = "List of HTTP URLs to probe with blackbox-exporter"
  type        = list(string)
  default     = []
}

variable "grafana_namespace" {
  description = "Namespace where Grafana is deployed — dashboard ConfigMap is created here"
  type        = string
  default     = "monitoring"
}

variable "scrape_interval" {
  description = "Prometheus scrape interval for blackbox probes"
  type        = string
  default     = "30s"
}

variable "probe_timeout" {
  description = "Timeout for each HTTP probe (passed to Probe CRD spec.scrapeTimeout)"
  type        = string
  default     = "10s"
}

variable "schedule_on_system_nodes" {
  description = "Pin the blackbox-exporter pod to the system node pool (nodeSelector kubernetes.azure.com/mode=system + CriticalAddonsOnly toleration). Set false to run on user nodes."
  type        = bool
  default     = true
}
