# ArgoCD Module

Deploys ArgoCD via Helm with optional SSO, repo authentication, App-of-Apps, and metrics scraping.

See [`docs/specs/argocd.md`](../../../../docs/specs/argocd.md) for full usage, all inputs, and the wealthyminds reference implementation.

## Basic Usage

```hcl
module "argocd" {
  source = "../modules/charts/argocd"

  enabled          = true
  namespace        = "argocd"
  ingress_hostname = "argocd.dev.example.com"
}
```

## App-of-Apps Usage

```hcl
module "argocd" {
  source = "../modules/charts/argocd"

  enabled       = true
  env           = "dev"
  chart_version = "7.7.16"

  aks_keyvault_name   = "kv-myproject-dev"
  resource_group_name = "rg-myproject-dev"

  enable_sso   = true
  project_name = "myproject"
  dns_zone     = "myproject.ai"
  tenant_id    = "<tenant-id>"
  org_domain   = "myorg.com"

  github_org_url   = "https://github.com/MyOrg"
  github_pat_value = var.github_pat

  argocd_instances_config = {
    dev = { cluster_url = "https://kubernetes.default.svc" }
  }
  argocd_project_source_repos = ["https://github.com/MyOrg/myrepo"]
  argocd_config_repo_url      = "https://github.com/MyOrg/myrepo"
}
```

## Access

```bash
# Retrieve admin password from Key Vault
az keyvault secret show --vault-name <kv> --name argocd-dev-admin-password --query value -o tsv

# Port-forward (dev — no ingress)
kubectl port-forward svc/argocd-server -n argocd-dev 8080:80
```
