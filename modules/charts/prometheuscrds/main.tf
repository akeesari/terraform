
# This module is responsible for managing the prometheus-operator-crds installation in a Kubernetes cluster.

locals {
  namespace_name = "prometheus-crds"
  helm_name      = "prometheus-operator-crds"
  chart_name     = "prometheus-operator-crds"
  repository     = "https://prometheus-community.github.io/helm-charts"
}

variable "prometheus_crds_version" {
  type        = string
  nullable    = false
  description = "prometheus-operator-crds Helm chart version to deploy."
}

variable "enabled" {
  type        = bool
  description = "Enable prometheus-operator-crds deployment."
  default     = true
}

variable "schedule_on_system_nodes" {
  type        = bool
  description = "Pin any installer jobs to the system node pool (nodeSelector kubernetes.azure.com/mode=system + CriticalAddonsOnly toleration). Set false to run on user nodes."
  default     = true
}

# Step-1: Create separate namespace for prometheus_crds resources
resource "kubernetes_namespace" "prometheus_crds" {
  count = var.enabled ? 1 : 0
  metadata {
    name = local.namespace_name
  }
  lifecycle {
    ignore_changes = [metadata]
  }
}

# Step-2: Install prometheus helm chart using terraform
resource "helm_release" "prometheus_crds" {
  count           = var.enabled ? 1 : 0
  name            = local.helm_name
  namespace       = local.namespace_name
  repository      = local.repository
  chart           = local.chart_name
  version         = var.prometheus_crds_version
  wait            = true
  timeout         = 300
  cleanup_on_fail = true

  values = [
    var.schedule_on_system_nodes ? yamlencode({
      nodeSelector = { "kubernetes.azure.com/mode" = "system" }
      tolerations  = [{ key = "CriticalAddonsOnly", operator = "Exists", effect = "NoSchedule" }]
    }) : ""
  ]

  depends_on = [kubernetes_namespace.prometheus_crds]

  lifecycle {
    ignore_changes = [
      # values
    ]
  }
}
