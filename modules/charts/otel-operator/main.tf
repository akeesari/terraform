# =============================================================================
# OpenTelemetry Operator Module
# Deploys the OpenTelemetry Operator with auto-instrumentation support
# =============================================================================

# -----------------------------------------------------------------------------
# Dedicated Namespace
# -----------------------------------------------------------------------------
resource "kubernetes_namespace" "otel_operator" {
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
# OpenTelemetry Operator Helm Release
# -----------------------------------------------------------------------------
resource "helm_release" "otel_operator" {
  name             = "opentelemetry-operator"
  repository       = "https://open-telemetry.github.io/opentelemetry-helm-charts"
  chart            = "opentelemetry-operator"
  version          = var.chart_version
  namespace        = kubernetes_namespace.otel_operator.metadata[0].name
  create_namespace = false
  cleanup_on_fail  = true
  wait             = true
  timeout          = 300

  values = [
    file("${path.module}/values.yaml"),
    var.schedule_on_system_nodes ? yamlencode({
      nodeSelector = { "kubernetes.azure.com/mode" = "system" }
      tolerations  = [{ key = "CriticalAddonsOnly", operator = "Exists", effect = "NoSchedule" }]
    }) : ""
  ]

  depends_on = [kubernetes_namespace.otel_operator]
}

# -----------------------------------------------------------------------------
# Auto-Instrumentation Configuration
# NOTE: The Instrumentation CRD is installed by the operator Helm chart above.
# This resource will fail on the first apply because the CRD doesn't exist yet.
# Apply this in a second wave after the operator is running, or create it manually.
# To enable: uncomment the resource below after the operator is successfully deployed.
# -----------------------------------------------------------------------------

# resource "kubernetes_manifest" "otel_instrumentation" {
#   manifest = yamldecode(file("${path.module}/otel_instrumentation.yaml"))
#   depends_on = [helm_release.otel_operator]
# }
