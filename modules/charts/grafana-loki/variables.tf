# =============================================================================
# Grafana Loki Module Variables
# =============================================================================

variable "enabled" {
  description = "Enable Loki log aggregation stack (Loki + Promtail + Grafana)."
  type        = bool
  default     = false
}

variable "loki_chart_version" {
  description = "Loki Helm chart version."
  type        = string
  default     = "6.29.0"
}

variable "promtail_chart_version" {
  description = "Promtail Helm chart version."
  type        = string
  default     = "6.16.6"
}

variable "grafana_chart_version" {
  description = "Grafana Helm chart version."
  type        = string
  default     = "8.15.0"
}

variable "grafana_host" {
  description = "Grafana ingress hostname (e.g. grafana.dev.example.com). Ingress is created when set."
  type        = string
  default     = ""
}

variable "grafana_admin_password" {
  description = "Grafana admin password. Sourced from Key Vault."
  type        = string
  sensitive   = true
  default     = ""
}

variable "ingress_class_name" {
  description = "Ingress class name for the Grafana ingress."
  type        = string
  default     = "nginx"
}

variable "cluster_issuer_name" {
  description = "cert-manager ClusterIssuer name for TLS certificates."
  type        = string
  default     = "letsencrypt-prod"
}

variable "application_namespace" {
  description = "Kubernetes namespace containing your application pods. Used in Loki alert rules to scope exception queries (e.g. 'myapp-dev')."
  type        = string
  default     = "default"
}

variable "schedule_on_system_nodes" {
  description = "Pin Loki and Grafana pods to the system node pool (nodeSelector + CriticalAddonsOnly toleration). Promtail (DaemonSet) gets only the toleration. Set false to run on user nodes."
  type        = bool
  default     = true
}
