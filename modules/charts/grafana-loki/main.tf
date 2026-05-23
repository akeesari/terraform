# =============================================================================
# Grafana Loki Stack — In-Cluster Log Aggregation & Visualization
# Deploys Loki (log backend), Promtail (log collector), and Grafana (UI).
# =============================================================================

# -----------------------------------------------------------------------------
# Namespace
# -----------------------------------------------------------------------------
resource "kubernetes_namespace" "monitoring" {
  count = var.enabled ? 1 : 0
  metadata {
    name = "monitoring"
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  lifecycle {
    ignore_changes = [metadata]
  }
}

# =============================================================================
# Loki Alert Rules — LogQL rules evaluated by the Loki ruler every 5 minutes.
# Mounted at /var/loki/rules/fake/ (Loki uses "fake" tenant when auth_enabled=false).
# =============================================================================
resource "kubernetes_config_map" "loki_rules" {
  count = var.enabled ? 1 : 0

  metadata {
    name      = "loki-rules"
    namespace = kubernetes_namespace.monitoring[0].metadata[0].name
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
      "app.kubernetes.io/component"  = "loki-ruler"
    }
  }

  data = {
    "exception-rules.yaml" = <<-EOT
groups:
  - name: application-exceptions
    interval: 5m
    rules:
      - alert: ApplicationExceptions
        expr: 'sum by (pod, exception_type) (count_over_time({namespace="${var.application_namespace}"} |= "Exception" | regexp "(?P<exception_type>[A-Za-z][A-Za-z0-9.]*Exception)" [30m])) > 0'
        for: 0m
        labels:
          severity: critical
        annotations:
          summary: "{{ $labels.pod }}: {{ $labels.exception_type }} ({{ $value | humanize }}x in last 30 min)"
          description: |
            Pod: {{ $labels.pod }}
            Exception: {{ $labels.exception_type }}
            Count (last 30 min): {{ $value | humanize }}

            ── Direct link to this pod's exceptions ──
            https://${var.grafana_host}/explore?left={"queries":[{"expr":"{namespace=\"${var.application_namespace}\",pod=\"{{ $labels.pod }}\"} |= \"Exception\"","queryType":"range","datasource":{"type":"loki"}}],"range":{"from":"now-6h","to":"now"}}

            ── All ${var.application_namespace} exceptions ──
            https://${var.grafana_host}/explore?left={"queries":[{"expr":"{namespace=\"${var.application_namespace}\"} |= \"Exception\"","queryType":"range","datasource":{"type":"loki"}}],"range":{"from":"now-6h","to":"now"}}
EOT
  }
}

# =============================================================================
# Loki — Log Aggregation Backend (Single-Binary / Monolithic Mode)
# =============================================================================
resource "helm_release" "loki" {
  count           = var.enabled ? 1 : 0
  name            = "loki"
  repository      = "https://grafana.github.io/helm-charts"
  chart           = "loki"
  version         = var.loki_chart_version
  namespace       = kubernetes_namespace.monitoring[0].metadata[0].name
  wait            = true
  timeout         = 300
  cleanup_on_fail = true

  values = [
    file("${path.module}/loki-values.yaml"),
    var.schedule_on_system_nodes ? yamlencode({
      singleBinary = {
        nodeSelector = { "kubernetes.azure.com/mode" = "system" }
        tolerations  = [{ key = "CriticalAddonsOnly", operator = "Exists", effect = "NoSchedule" }]
      }
    }) : ""
  ]

  depends_on = [kubernetes_namespace.monitoring, kubernetes_config_map.loki_rules]
}

# =============================================================================
# Promtail — Log Collector DaemonSet (ships pod logs to Loki)
# =============================================================================
resource "helm_release" "promtail" {
  count           = var.enabled ? 1 : 0
  name            = "promtail"
  repository      = "https://grafana.github.io/helm-charts"
  chart           = "promtail"
  version         = var.promtail_chart_version
  namespace       = kubernetes_namespace.monitoring[0].metadata[0].name
  wait            = true
  timeout         = 300
  cleanup_on_fail = true

  values = [
    file("${path.module}/promtail-values.yaml"),
    # Promtail is a DaemonSet — toleration only (no nodeSelector) so it ships logs from all nodes
    var.schedule_on_system_nodes ? yamlencode({
      tolerations = [{ key = "CriticalAddonsOnly", operator = "Exists", effect = "NoSchedule" }]
    }) : ""
  ]

  depends_on = [helm_release.loki]
}

# =============================================================================
# Grafana — Visualization & Dashboards
# =============================================================================
resource "helm_release" "grafana" {
  count           = var.enabled ? 1 : 0
  name            = "grafana"
  repository      = "https://grafana.github.io/helm-charts"
  chart           = "grafana"
  version         = var.grafana_chart_version
  namespace       = kubernetes_namespace.monitoring[0].metadata[0].name
  wait            = true
  timeout         = 300
  cleanup_on_fail = true

  values = [
    file("${path.module}/grafana-values.yaml"),
    var.schedule_on_system_nodes ? yamlencode({
      nodeSelector = { "kubernetes.azure.com/mode" = "system" }
      tolerations  = [{ key = "CriticalAddonsOnly", operator = "Exists", effect = "NoSchedule" }]
    }) : ""
  ]

  dynamic "set_sensitive" {
    for_each = var.grafana_admin_password != "" ? [var.grafana_admin_password] : []
    content {
      name  = "adminPassword"
      value = set_sensitive.value
    }
  }

  depends_on = [helm_release.loki]
}

# -----------------------------------------------------------------------------
# Grafana Ingress (cert-manager TLS)
# -----------------------------------------------------------------------------
resource "kubernetes_ingress_v1" "grafana" {
  count = var.enabled && var.grafana_host != "" ? 1 : 0

  metadata {
    name      = "grafana"
    namespace = kubernetes_namespace.monitoring[0].metadata[0].name
    annotations = {
      "cert-manager.io/cluster-issuer" = var.cluster_issuer_name
    }
  }

  spec {
    ingress_class_name = var.ingress_class_name

    tls {
      hosts       = [var.grafana_host]
      secret_name = "grafana-tls"
    }

    rule {
      host = var.grafana_host
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "grafana"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }

  depends_on = [helm_release.grafana]
}
