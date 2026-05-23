variable "enabled" {
  type        = bool
  description = "Toggle deployment of cert-manager Helm release."
  default     = true
}

variable "namespace" {
  type        = string
  description = "Target namespace for cert-manager (Kubernetes resources)."
  default     = "cert-manager"
}

variable "release_name" {
  type        = string
  description = "Helm release name for cert-manager."
  default     = "cert-manager"
}

variable "chart_repository" {
  type        = string
  description = "Helm chart repository URL for cert-manager."
  default     = "https://charts.jetstack.io"
}

variable "chart_version" {
  type        = string
  description = "Specific cert-manager chart version to deploy."
  default     = "v1.16.2"

  validation {
    condition     = var.chart_version != ""
    error_message = "chart_version must be a non-empty pinned version (e.g. \"v1.16.2\") to ensure reproducible deployments."
  }
}

variable "install_crds" {
  type        = bool
  description = "Install custom resource definitions (CRDs). Should be true on first install; false on upgrades to avoid overwrite issues."
  default     = true
}

variable "extra_values" {
  type        = map(any)
  description = "Additional values to merge into the chart values (e.g., webhook resources)."
  default     = {}
}

variable "enable_cluster_issuer" {
  type        = bool
  description = "Toggle creation of the production Let's Encrypt ClusterIssuer."
  default     = true
}

variable "ingress_class_name" {
  type        = string
  description = "Ingress class name for ACME HTTP01 solver (webapprouting.kubernetes.azure.com for AKS Web App Routing)"
  default     = "nginx"
}

variable "cluster_issuer_email" {
  type        = string
  description = "Email used for ACME account registration (required if enable_cluster_issuer is true)."
  default     = ""
}

variable "tolerate_system_taints" {
  type        = bool
  description = "Deprecated. Use schedule_on_system_nodes instead."
  default     = null
}

variable "schedule_on_system_nodes" {
  type        = bool
  description = "Pin all cert-manager pods to the system node pool (nodeSelector kubernetes.azure.com/mode=system + CriticalAddonsOnly toleration). Set false to run on user nodes."
  default     = true
}
