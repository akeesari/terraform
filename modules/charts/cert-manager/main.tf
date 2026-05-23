terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.19"
    }
  }
}

locals {
  _sys_node_selector = var.schedule_on_system_nodes ? { "kubernetes.azure.com/mode" = "system" } : {}
  _sys_tolerations   = var.schedule_on_system_nodes ? [{ key = "CriticalAddonsOnly", operator = "Exists", effect = "NoSchedule" }] : []
  system_scheduling = {
    nodeSelector = local._sys_node_selector
    tolerations  = local._sys_tolerations
  }
  base_values = { installCRDs = var.install_crds }
  taint_values = {
    nodeSelector    = local._sys_node_selector
    tolerations     = local._sys_tolerations
    cainjector      = local.system_scheduling
    webhook         = local.system_scheduling
    startupapicheck = local.system_scheduling
  }
  merged_values = merge(local.base_values, local.taint_values, var.extra_values)
}

resource "kubernetes_namespace" "cert_manager" {
  count = var.enabled ? 1 : 0
  metadata { name = var.namespace }

  lifecycle {
    ignore_changes = [metadata]
  }
}

resource "helm_release" "cert_manager" {
  count            = var.enabled ? 1 : 0
  name             = var.release_name
  repository       = var.chart_repository
  chart            = "cert-manager"
  version          = var.chart_version != "" ? var.chart_version : null
  namespace        = var.namespace
  create_namespace = false
  values           = [yamlencode(local.merged_values)]
  timeout          = 600
  wait             = true
  cleanup_on_fail  = true
  disable_webhooks = false
  depends_on       = [kubernetes_namespace.cert_manager]
}

resource "kubectl_manifest" "cluster_issuer" {
  count = var.enabled && var.enable_cluster_issuer ? 1 : 0
  yaml_body = templatefile("${path.module}/clusterissuer.yaml", {
    email         = var.cluster_issuer_email
    ingress_class = var.ingress_class_name
  })
  server_side_apply = true # Required: avoids "resourceVersion must be specified for update" error on existing ClusterIssuer
  force_conflicts   = true # Allow Terraform to take ownership if resource was created outside Terraform
  depends_on        = [helm_release.cert_manager]
}
