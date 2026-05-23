variable "enabled" {
  type        = bool
  description = "Toggle deployment of ingress-nginx Helm release."
  default     = true
}

variable "namespace" {
  type        = string
  description = "Target namespace for ingress-nginx deployment."
  default     = "ingress-nginx"
}

variable "release_name" {
  type        = string
  description = "Helm release name for ingress-nginx."
  default     = "ingress-nginx"
}

variable "chart_version" {
  type        = string
  description = "Ingress-nginx Helm chart version to deploy."
  default     = "4.10.0"
}

variable "loadbalancer_annotations" {
  type        = map(string)
  description = "Annotations applied to the ingress controller Service for load balancer configuration."
  default = {
    "service.beta.kubernetes.io/azure-load-balancer-health-probe-request-path" = "/healthz"
  }
}

variable "public_ip_name" {
  type        = string
  description = "Existing Public IP name (string) to assign to the ingress controller Service LB; leave empty to let Azure allocate one."
  default     = ""
}

variable "tolerate_system_taints" {
  type        = bool
  description = "Deprecated. Use schedule_on_system_nodes instead."
  default     = null
}

variable "schedule_on_system_nodes" {
  type        = bool
  description = "Pin controller and webhook pods to the system node pool (nodeSelector kubernetes.azure.com/mode=system + CriticalAddonsOnly toleration). Set false to run on user nodes."
  default     = true
}
