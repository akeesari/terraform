# =============================================================================
# kube-prometheus-stack Helm Chart Module
# Deploys Prometheus Operator, Prometheus, Alertmanager, and Grafana sidecar
# support. Uses the prometheus-community/kube-prometheus-stack chart.
# Pattern follows infra/modules/charts/grafana-loki — single .tf per module.
# =============================================================================

# -----------------------------------------------------------------------------
# Namespace — only created when create_namespace = true.
# When grafana-loki (or another module) already owns the 'monitoring' namespace,
# set create_namespace = false to avoid "namespace already exists" conflicts.
# -----------------------------------------------------------------------------
resource "kubernetes_namespace" "monitoring" {
  count = var.enabled && var.create_namespace ? 1 : 0

  metadata {
    name = var.namespace
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  lifecycle {
    ignore_changes = [metadata]
  }
}

# When create_namespace = false the namespace pre-exists (owned by grafana-loki).
# Using a local avoids repeating the conditional everywhere.
locals {
  namespace = var.namespace
}

# -----------------------------------------------------------------------------
# kube-prometheus-stack Helm Release
# -----------------------------------------------------------------------------
resource "helm_release" "kube_prometheus_stack" {
  count = var.enabled ? 1 : 0

  name             = "kube-prometheus-stack"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  version          = var.chart_version
  namespace        = local.namespace
  create_namespace = false
  cleanup_on_fail  = true
  wait             = true
  timeout          = 600

  values = [
    templatefile("${path.module}/prometheus-values.yaml", {
      retention                = var.prometheus_retention
      storage_size             = var.prometheus_storage_size
      smtp_smarthost           = var.alertmanager_smtp_smarthost
      smtp_from                = var.alertmanager_smtp_from
      smtp_auth_username       = var.alertmanager_smtp_auth_username
      smtp_auth_password       = var.alertmanager_smtp_auth_password
      alert_email_to           = var.alertmanager_alert_email_to
      loki_exceptions_template = file("${path.module}/loki-exceptions.tmpl")
    }),
    # System node pool scheduling — pins Deployments/StatefulSets to system nodes.
    # prometheus-node-exporter is a DaemonSet that must run on all nodes; it gets
    # only the toleration (no nodeSelector) so it keeps collecting from user nodes.
    var.schedule_on_system_nodes ? yamlencode({
      prometheusOperator = {
        nodeSelector = { "kubernetes.azure.com/mode" = "system" }
        tolerations  = [{ key = "CriticalAddonsOnly", operator = "Exists", effect = "NoSchedule" }]
        admissionWebhooks = {
          patch = {
            tolerations = [{ key = "CriticalAddonsOnly", operator = "Exists", effect = "NoSchedule" }]
          }
        }
      }
      prometheus = {
        prometheusSpec = {
          nodeSelector = { "kubernetes.azure.com/mode" = "system" }
          tolerations  = [{ key = "CriticalAddonsOnly", operator = "Exists", effect = "NoSchedule" }]
        }
      }
      alertmanager = {
        alertmanagerSpec = {
          nodeSelector = { "kubernetes.azure.com/mode" = "system" }
          tolerations  = [{ key = "CriticalAddonsOnly", operator = "Exists", effect = "NoSchedule" }]
        }
      }
      "kube-state-metrics" = {
        nodeSelector = { "kubernetes.azure.com/mode" = "system" }
        tolerations  = [{ key = "CriticalAddonsOnly", operator = "Exists", effect = "NoSchedule" }]
      }
      "prometheus-node-exporter" = {
        # DaemonSet — toleration only, no nodeSelector so it runs on all nodes
        tolerations = [{ key = "CriticalAddonsOnly", operator = "Exists", effect = "NoSchedule" }]
      }
    }) : ""
  ]

  depends_on = [kubernetes_namespace.monitoring]
}
