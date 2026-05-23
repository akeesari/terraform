# =============================================================================
# Blackbox Exporter Module
# Deploys prometheus-blackbox-exporter and wires it to kube-prometheus-stack
# via ServiceMonitor and PrometheusRule. Also provisions a Grafana dashboard
# ConfigMap in the existing Grafana namespace.
# =============================================================================

# -----------------------------------------------------------------------------
# Dedicated Namespace
# -----------------------------------------------------------------------------
resource "kubernetes_namespace" "blackbox" {
  count = var.enabled ? 1 : 0

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
# Blackbox Exporter Helm Release
# -----------------------------------------------------------------------------
resource "helm_release" "blackbox_exporter" {
  count = var.enabled ? 1 : 0

  name             = "blackbox-exporter"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "prometheus-blackbox-exporter"
  version          = var.chart_version
  namespace        = kubernetes_namespace.blackbox[0].metadata[0].name
  create_namespace = false
  cleanup_on_fail  = true
  wait             = true
  timeout          = 300

  values = [
    templatefile("${path.module}/blackbox-values.yaml", {
      probe_timeout = var.probe_timeout
    }),
    var.schedule_on_system_nodes ? yamlencode({
      nodeSelector = { "kubernetes.azure.com/mode" = "system" }
      tolerations  = [{ key = "CriticalAddonsOnly", operator = "Exists", effect = "NoSchedule" }]
    }) : ""
  ]

  depends_on = [kubernetes_namespace.blackbox]
}

# -----------------------------------------------------------------------------
# Probe CRD — purpose-built Prometheus Operator resource for external URL probing.
# Generates one scrape target per URL in targets.staticConfig.static[], with
# correct relabeling so each URL appears as a separate `instance` label in metrics.
# This replaces the ServiceMonitor approach which cannot correctly fan out to
# multiple separate targets from a single params.target list.
# -----------------------------------------------------------------------------
resource "kubernetes_manifest" "blackbox_probe" {
  count = var.enabled ? 1 : 0

  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "Probe"
    metadata = {
      name      = "website-http-probes"
      namespace = kubernetes_namespace.blackbox[0].metadata[0].name
      labels = {
        "release"                      = "kube-prometheus-stack"
        "app.kubernetes.io/managed-by" = "terraform"
      }
    }
    spec = {
      jobName = "blackbox-http"
      prober = {
        # scheme=http here means Prometheus talks to the blackbox exporter via HTTP.
        # The exporter itself handles HTTPS probing of the target URLs.
        url    = "blackbox-exporter-prometheus-blackbox-exporter.${var.namespace}.svc.cluster.local:9115"
        path   = "/probe"
        scheme = "http"
      }
      module        = "http_2xx"
      interval      = var.scrape_interval
      scrapeTimeout = var.probe_timeout
      targets = {
        staticConfig = {
          static = var.target_urls
          labels = {}
        }
      }
    }
  }

  depends_on = [helm_release.blackbox_exporter]
}

# -----------------------------------------------------------------------------
# PrometheusRule — WebsiteDown alert fires when probe_success == 0 for 1 minute
# -----------------------------------------------------------------------------
resource "kubernetes_manifest" "blackbox_probe_alert" {
  count = var.enabled ? 1 : 0

  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "PrometheusRule"
    metadata = {
      name      = "blackbox-exporter-alerts"
      namespace = kubernetes_namespace.blackbox[0].metadata[0].name
      labels = {
        "release"                      = "kube-prometheus-stack"
        "app.kubernetes.io/managed-by" = "terraform"
      }
    }
    spec = {
      groups = [
        {
          name = "blackbox.rules"
          rules = [
            {
              alert = "WebsiteDown"
              expr  = "probe_success == 0"
              for   = "1m"
              labels = {
                severity = "critical"
              }
              annotations = {
                summary     = "Website {{ $labels.instance }} is down"
                description = "Blackbox probe for {{ $labels.instance }} has been failing for more than 1 minute. The HTTP endpoint is not returning a 2xx response."
              }
            },
            {
              alert = "SSLCertExpiringSoon"
              expr  = "(probe_ssl_earliest_cert_expiry - time()) / 86400 < 30"
              for   = "1h"
              labels = {
                severity = "warning"
              }
              annotations = {
                summary     = "SSL certificate for {{ $labels.instance }} expiring soon"
                description = "The SSL certificate for {{ $labels.instance }} expires in less than 30 days. Renew it before it causes downtime."
              }
            },
            {
              alert = "ProbeSlowHTTP"
              expr  = "avg_over_time(probe_duration_seconds[5m]) > 2"
              for   = "5m"
              labels = {
                severity = "warning"
              }
              annotations = {
                summary     = "Slow HTTP response from {{ $labels.instance }}"
                description = "HTTP probe for {{ $labels.instance }} has an average response time above 2 seconds over the last 5 minutes."
              }
            },
            {
              alert = "SchwabTokenExpiring"
              expr  = "probe_success{instance=~\".*schwab-token.*\"} == 0"
              for   = "5m"
              labels = {
                severity = "critical"
              }
              annotations = {
                summary     = "Schwab token TTL below 5 hours — renewal required"
                description = "The /health/schwab-token endpoint is returning unhealthy. The schwab:tokens Redis key TTL has dropped below 5 hours or the key is missing. Run renew-schwab-token.ps1 and push to AKS."
              }
            }
          ]
        }
      ]
    }
  }

  depends_on = [helm_release.blackbox_exporter]
}

# -----------------------------------------------------------------------------
# Grafana Dashboard ConfigMap
# Labelled with grafana_dashboard=1 so Grafana's sidecar auto-imports it.
# Placed in the grafana_namespace where the existing Grafana instance lives.
# -----------------------------------------------------------------------------
resource "kubernetes_config_map" "blackbox_dashboard" {
  count = var.enabled ? 1 : 0

  metadata {
    name      = "blackbox-exporter-dashboard"
    namespace = var.grafana_namespace
    labels = {
      "grafana_dashboard"            = "1"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  data = {
    "blackbox-exporter.json" = file("${path.module}/dashboard.json")
  }
}
