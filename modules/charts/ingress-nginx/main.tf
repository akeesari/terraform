locals {
  annotations = var.loadbalancer_annotations
}

resource "kubernetes_namespace" "ingress" {
  count = var.enabled ? 1 : 0
  metadata { name = var.namespace }

  lifecycle {
    ignore_changes = [metadata]
  }
}

resource "helm_release" "ingress_nginx" {
  count            = var.enabled ? 1 : 0
  name             = var.release_name
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  version          = var.chart_version
  namespace        = var.namespace
  create_namespace = false

  values = [
    yamlencode({
      controller = {
        nodeSelector = var.schedule_on_system_nodes ? { "kubernetes.azure.com/mode" = "system" } : {}
        tolerations  = var.schedule_on_system_nodes ? [{ key = "CriticalAddonsOnly", operator = "Exists", effect = "NoSchedule" }] : []
        service = {
          annotations    = local.annotations
          loadBalancerIP = var.public_ip_name != "" ? var.public_ip_name : null
        }
        admissionWebhooks = {
          patch = {
            nodeSelector = var.schedule_on_system_nodes ? { "kubernetes.azure.com/mode" = "system" } : {}
            tolerations  = var.schedule_on_system_nodes ? [{ key = "CriticalAddonsOnly", operator = "Exists", effect = "NoSchedule" }] : []
          }
        }
      }
    })
  ]
  timeout          = 600
  cleanup_on_fail  = true
  disable_webhooks = false
  wait             = true

  depends_on = [kubernetes_namespace.ingress]
}
