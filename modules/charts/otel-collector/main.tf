# =============================================================================
# OpenTelemetry Collector Module
# Deploys the OpenTelemetry Collector with Azure Monitor integration
# =============================================================================

# -----------------------------------------------------------------------------
# Dedicated Namespace
# -----------------------------------------------------------------------------
resource "kubernetes_namespace" "otel_collector" {
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

# -----------------------------------------------------------------------------
# Key Vault Data Sources — Application Insights Connection String
# -----------------------------------------------------------------------------
data "azurerm_key_vault" "cluster_kv" {
  name                = var.aks_keyvault_name
  resource_group_name = var.resource_group_name
}

data "azurerm_key_vault_secret" "appi_connection_string" {
  name         = "${var.cluster_name}-appi-connection-string"
  key_vault_id = data.azurerm_key_vault.cluster_kv.id
}

# -----------------------------------------------------------------------------
# Render Helm Values with App Insights Connection String
# -----------------------------------------------------------------------------
locals {
  otel_values = templatefile("${path.module}/values.yaml", {
    appi_connection_string = data.azurerm_key_vault_secret.appi_connection_string.value
  })
}

# -----------------------------------------------------------------------------
# OpenTelemetry Collector Helm Release
# -----------------------------------------------------------------------------
resource "helm_release" "otel_collector" {
  name             = "opentelemetry-collector"
  repository       = "https://open-telemetry.github.io/opentelemetry-helm-charts"
  chart            = "opentelemetry-collector"
  version          = var.chart_version
  namespace        = kubernetes_namespace.otel_collector.metadata[0].name
  create_namespace = false
  cleanup_on_fail  = true
  wait             = true
  timeout          = 300

  values = [
    local.otel_values,
    var.schedule_on_system_nodes ? yamlencode({
      nodeSelector = { "kubernetes.azure.com/mode" = "system" }
      tolerations  = [{ key = "CriticalAddonsOnly", operator = "Exists", effect = "NoSchedule" }]
    }) : ""
  ]

  depends_on = [kubernetes_namespace.otel_collector]
}
