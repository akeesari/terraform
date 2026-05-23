# =============================================================================
# pgAdmin — PostgreSQL Web Admin UI
# Deploys pgAdmin4 via Helm with a pre-configured PostgreSQL server definition
# and cert-manager-managed TLS ingress.
# =============================================================================

terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.38"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.13"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.19"
    }
  }
}

resource "kubernetes_namespace" "pgadmin" {
  count = var.enabled ? 1 : 0
  metadata {
    name = "pgadmin"
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  lifecycle {
    ignore_changes = [metadata]
  }
}

resource "helm_release" "pgadmin" {
  count           = var.enabled ? 1 : 0
  name            = "pgadmin"
  repository      = "https://helm.runix.net"
  chart           = "pgadmin4"
  version         = var.chart_version
  namespace       = kubernetes_namespace.pgadmin[0].metadata[0].name
  wait            = true
  timeout         = 300
  cleanup_on_fail = true

  values = [
    file("${path.module}/pgadmin-values.yaml"),
    var.schedule_on_system_nodes ? yamlencode({
      nodeSelector = { "kubernetes.azure.com/mode" = "system" }
      tolerations  = [{ key = "CriticalAddonsOnly", operator = "Exists", effect = "NoSchedule" }]
    }) : ""
  ]

  set {
    name  = "env.email"
    value = var.admin_email
  }

  set_sensitive {
    name  = "env.password"
    value = var.admin_password
  }

  set {
    name  = "serverDefinitions.enabled"
    value = "true"
  }

  set {
    name  = "serverDefinitions.servers.${var.project_name}.Name"
    value = "${var.project_name} PostgreSQL"
  }

  set {
    name  = "serverDefinitions.servers.${var.project_name}.Host"
    value = var.postgres_host
  }

  set {
    name  = "serverDefinitions.servers.${var.project_name}.Port"
    value = "5432"
  }

  set {
    name  = "serverDefinitions.servers.${var.project_name}.Username"
    value = var.postgres_username
  }

  set {
    name  = "serverDefinitions.servers.${var.project_name}.MaintenanceDB"
    value = var.postgres_database
  }

  set {
    name  = "serverDefinitions.servers.${var.project_name}.SSLMode"
    value = "require"
  }

  lifecycle {
    ignore_changes = [values, version]
  }

  depends_on = [kubernetes_namespace.pgadmin]
}

resource "kubectl_manifest" "pgadmin_ingress" {
  count = var.enabled && var.ingress_hostname != "" ? 1 : 0
  yaml_body = yamlencode({
    apiVersion = "networking.k8s.io/v1"
    kind       = "Ingress"
    metadata = {
      name      = "pgadmin"
      namespace = kubernetes_namespace.pgadmin[0].metadata[0].name
      annotations = {
        "cert-manager.io/cluster-issuer" = var.cluster_issuer_name
      }
    }
    spec = {
      ingressClassName = var.ingress_class_name
      tls = [{
        hosts      = [var.ingress_hostname]
        secretName = "pgadmin-tls"
      }]
      rules = [{
        host = var.ingress_hostname
        http = {
          paths = [{
            path     = "/"
            pathType = "Prefix"
            backend = {
              service = {
                name = "pgadmin-pgadmin4"
                port = { number = 80 }
              }
            }
          }]
        }
      }]
    }
  })

  depends_on = [helm_release.pgadmin]
}
