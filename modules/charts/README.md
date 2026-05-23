# Terraform Chart Modules

Helm-based Kubernetes modules for in-cluster tooling. Each module manages one logical concern (ingress, observability, GitOps, etc.) via Terraform-managed Helm releases and Kubernetes manifests.

All modules follow the conventions in [`.github/instructions/terraform-modules.instructions.md`](../../../.github/instructions/terraform-modules.instructions.md) adapted for Kubernetes: the `name`, `resource_group_name`, and `location` Azure-specific requirements are replaced by Kubernetes equivalents (`namespace`, `release_name`).

---

## Module Reference

| Module | Tool | Manages |
|---|---|---|
| [`argocd`](./argocd/) | Argo CD | GitOps controller, app-of-apps pattern, AppProject, repo secrets, ingress |
| [`blackbox-exporter`](./blackbox-exporter/) | Prometheus Blackbox Exporter | HTTP/HTTPS endpoint probing, Probe CRD, PrometheusRule alerts, Grafana dashboard |
| [`cert_manager`](./cert_manager/) | cert-manager | TLS certificate automation, Let's Encrypt ClusterIssuer |
| [`grafana-loki`](./grafana-loki/) | Loki + Promtail + Grafana | Log aggregation, Loki ruler alert rules, Grafana ingress |
| [`ingress_nginx`](./ingress_nginx/) | ingress-nginx | L7 ingress controller, Azure Load Balancer integration |
| [`kube-prometheus-stack`](./kube-prometheus-stack/) | kube-prometheus-stack | Prometheus Operator, Prometheus, Alertmanager with SMTP alerting |
| [`pgadmin`](./pgadmin/) | pgAdmin 4 | PostgreSQL web admin UI with pre-configured server definitions, ingress |
| [`prometheuscrds`](./prometheuscrds/) | prometheus-operator-crds | Standalone CRD installation (install before kube-prometheus-stack) |

---

## Conventions

- **Feature flags** — all modules expose an `enabled` (or `enable`) variable (default `false` for optional tools, `true` for foundational ones). Use `count = var.enabled ? 1 : 0` everywhere.
- **Lifecycle protection** — all namespace resources carry `lifecycle { prevent_destroy = true }` to guard against accidental deletion of in-use namespaces.
- **Helm reliability** — every `helm_release` sets `cleanup_on_fail = true`, `wait = true`, and a `timeout` of at least 300 s.
- **Pinned chart versions** — chart versions are always explicit variables with stable defaults; empty/latest is rejected where validation is applied.
- **Sensitive inputs** — variables holding credentials (`admin_password_hash`, `repositories`, `grafana_admin_password`, `pgadmin_password`, etc.) are marked `sensitive = true`.
- **Namespace ownership** — each module owns exactly one namespace. When two modules share a namespace (e.g., `grafana-loki` and `kube-prometheus-stack` both use `monitoring`), set `create_namespace = false` on the second consumer to avoid conflicts.

---

## Deployment Order

The modules have inter-dependencies. Deploy in this order:

```
1. prometheuscrds          # CRDs must exist before kube-prometheus-stack
2. cert_manager            # ClusterIssuer needed by ingress/argocd
3. ingress_nginx           # Ingress class needed by argocd, pgadmin
4. kube-prometheus-stack   # Prometheus Operator (with create_namespace = true)
5. grafana-loki            # Shares monitoring namespace (set create_namespace = false in kube-prometheus-stack OR grafana-loki)
6. blackbox-exporter       # Depends on Prometheus Operator CRDs and kube-prometheus-stack
7. argocd                  # Independent, but needs cert-manager + ingress
8. pgadmin                 # Independent, needs cert-manager + ingress
```

---

## Usage Examples

### ingress-nginx (minimal)

```hcl
module "ingress_nginx" {
  source = "../modules/charts/ingress_nginx"

  enable       = true
  namespace    = "ingress-nginx"
  chart_version = "4.10.0"

  loadbalancer_annotations = {
    "service.beta.kubernetes.io/azure-load-balancer-resource-group" = "rg-aks-prod"
    "service.beta.kubernetes.io/azure-load-balancer-health-probe-request-path" = "/healthz"
  }
}
```

### cert-manager + ClusterIssuer

```hcl
module "cert_manager" {
  source = "../modules/charts/cert_manager"

  enable                = true
  chart_version         = "v1.16.2"
  enable_cluster_issuer = true
  cluster_issuer_email  = "ops@example.com"
  ingress_class_name    = "nginx"
}
```

### kube-prometheus-stack

```hcl
module "kube_prometheus_stack" {
  source = "../modules/charts/kube-prometheus-stack"

  enabled                        = true
  chart_version                  = "65.1.1"
  create_namespace               = true
  prometheus_retention           = "30d"
  prometheus_storage_size        = "20Gi"
  alertmanager_smtp_from         = "alerts@example.com"
  alertmanager_smtp_auth_username = "alerts@example.com"
  alertmanager_smtp_auth_password = var.smtp_password  # from Key Vault
  alertmanager_alert_email_to    = "oncall@example.com"
}
```

### Loki + Grafana

```hcl
module "grafana_loki" {
  source = "../modules/charts/grafana-loki"

  enabled               = true
  grafana_host          = "grafana.prod.example.com"
  grafana_admin_password = var.grafana_password  # from Key Vault
  cluster_issuer_name   = "letsencrypt-prod"
  ingress_class_name    = "nginx"
}
```

### ArgoCD with app-of-apps

```hcl
module "argocd" {
  source = "../modules/charts/argocd"

  enabled          = true
  ingress_hostname = "argocd.prod.example.com"

  enable_app_of_apps = true
  projects = [{
    name        = "myapp"
    description = "My application project"
    repo_urls   = ["https://github.com/myorg/myapp"]
  }]
  repositories = [{
    name     = "myapp-repo"
    url      = "https://github.com/myorg/myapp"
    username = "git"
    password = var.github_pat  # from Key Vault
  }]
  root_app_repo_url = "https://github.com/myorg/myapp"
  app_path          = "helm/apps"
  target_revision   = "main"
}
```

### Blackbox Exporter

```hcl
module "blackbox_exporter" {
  source = "../modules/charts/blackbox-exporter"

  enabled     = true
  target_urls = [
    "https://api.example.com/health",
    "https://www.example.com",
  ]
  scrape_interval = "60s"
}
```

### pgAdmin

```hcl
module "pgadmin" {
  source = "../modules/charts/pgadmin"

  pgadmin_enabled     = true
  pgadmin_host        = "pgadmin.prod.example.com"
  pgadmin_admin_email = "dba@example.com"
  pgadmin_password    = var.pgadmin_password  # from Key Vault
  postgres_host       = module.postgres.fqdn
  postgres_database   = "mydb"
  postgres_username   = "pgadmin_ro"
  project_name        = "myapp"
}
```
