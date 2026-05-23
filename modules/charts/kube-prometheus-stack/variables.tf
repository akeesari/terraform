# =============================================================================
# kube-prometheus-stack Module Variables
# =============================================================================

variable "enabled" {
  description = "Enable kube-prometheus-stack deployment"
  type        = bool
  default     = false
}

variable "chart_version" {
  description = "kube-prometheus-stack Helm chart version"
  type        = string
  default     = "65.1.1"
}

variable "namespace" {
  description = "Kubernetes namespace for kube-prometheus-stack"
  type        = string
  default     = "monitoring"
}

variable "create_namespace" {
  description = "Create the namespace. Set to false when another module (e.g., grafana-loki) already owns the namespace."
  type        = bool
  default     = true
}

variable "prometheus_retention" {
  description = "Prometheus data retention period (e.g., '15d')"
  type        = string
  default     = "15d"
}

variable "prometheus_storage_size" {
  description = "Prometheus persistent volume size"
  type        = string
  default     = "10Gi"
}

# =============================================================================
# Alertmanager SMTP Variables
# =============================================================================

variable "alertmanager_smtp_smarthost" {
  description = "SMTP server host:port for Alertmanager email notifications"
  type        = string
  default     = "smtp.gmail.com:587"
}

variable "alertmanager_smtp_from" {
  description = "From email address for Alertmanager notifications"
  type        = string
  default     = ""
}

variable "alertmanager_smtp_auth_username" {
  description = "SMTP authentication username (usually same as from address)"
  type        = string
  default     = ""
}

variable "alertmanager_smtp_auth_password" {
  description = "SMTP authentication password or app password"
  type        = string
  sensitive   = true
  default     = ""
}

variable "alertmanager_alert_email_to" {
  description = "Recipient email address for alerts"
  type        = string
  default     = ""
}

variable "tolerate_system_taints" {
  description = "Deprecated. Use schedule_on_system_nodes instead."
  type        = bool
  default     = null
}

variable "schedule_on_system_nodes" {
  description = "Pin Operator/Prometheus/Alertmanager/kube-state-metrics pods to the system node pool. prometheus-node-exporter (DaemonSet) gets only the toleration so it still runs on all nodes."
  type        = bool
  default     = true
}
