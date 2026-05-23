terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.19"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

locals {
  # Use argocd-{env} namespace when env is provided; fall back to var.namespace for backwards compat.
  effective_namespace = var.env != "" ? "argocd-${var.env}" : var.namespace

  kv_enabled = var.enabled && var.aks_keyvault_name != "" && var.resource_group_name != ""

  # Admin password: prefer auto-generated (stored in KV) over manually provided hash.
  # terraform_data.admin_bcrypt_hash stores the bcrypt hash once on first apply and
  # never re-hashes, preventing perpetual Helm drift.
  effective_admin_password_hash = var.enabled ? (
    var.admin_password_hash != "" ? var.admin_password_hash :
    length(terraform_data.admin_bcrypt_hash) > 0 ? terraform_data.admin_bcrypt_hash[0].output : ""
  ) : ""

  # Source repo for the App-of-Apps root Application.
  # Priority: explicit var → ADO helmcharts repo (when ado_org_name set) → first entry of source repos list.
  effective_config_repo_url = var.argocd_config_repo_url != "" ? var.argocd_config_repo_url : (
    var.ado_org_name != "" ? "https://dev.azure.com/${var.ado_org_name}/DevOps/_git/helmcharts" : (
      length(var.argocd_project_source_repos) > 0 ? var.argocd_project_source_repos[0] : ""
    )
  )
}

# ArgoCD Helm Chart Module

resource "kubernetes_namespace" "argocd" {
  count = var.enabled && var.create_namespace ? 1 : 0

  metadata {
    name = local.effective_namespace
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  lifecycle {
    ignore_changes = [metadata]
  }
}

resource "helm_release" "argocd" {
  count = var.enabled ? 1 : 0

  name             = var.release_name
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = var.chart_version
  namespace        = local.effective_namespace
  create_namespace = false
  cleanup_on_fail  = true
  skip_crds        = true # CRDs already exist in cluster; skip to avoid ownership-annotation conflict
  timeout          = var.timeout

  values = [
    yamlencode({
      global = {
        nodeSelector = var.schedule_on_system_nodes ? { "kubernetes.azure.com/mode" = "system" } : {}
        tolerations  = var.schedule_on_system_nodes ? [{ key = "CriticalAddonsOnly", operator = "Exists", effect = "NoSchedule" }] : []
      }
      server = {
        extraArgs = ["--insecure"]
        service = {
          type = "ClusterIP"
        }
      }
      configs = {
        params = {
          "server.insecure" = true
        }
      }
      crds = {
        install = false # CRDs pre-exist; keep = true ensures they are not deleted on uninstall
        keep    = true
      }
    })
  ]

  # Admin password — auto-generated or manually provided bcrypt hash
  dynamic "set_sensitive" {
    for_each = local.effective_admin_password_hash != "" ? [local.effective_admin_password_hash] : []
    content {
      name  = "configs.secret.argocdServerAdminPassword"
      value = set_sensitive.value
    }
  }

  dynamic "set" {
    for_each = var.additional_set_values
    content {
      name  = set.value.name
      value = set.value.value
    }
  }

  depends_on = [kubernetes_namespace.argocd]
}

# Ingress for ArgoCD Server with TLS (using YAML template)
# Auto-enabled when ingress_hostname is provided
resource "kubernetes_manifest" "argocd_ingress" {
  count = var.enabled && var.ingress_hostname != "" ? 1 : 0

  manifest = yamldecode(templatefile("${path.module}/ingress.yaml", {
    release_name        = var.release_name
    namespace           = local.effective_namespace
    hostname            = var.ingress_hostname
    ingress_class_name  = var.ingress_class_name
    cluster_issuer_name = var.cluster_issuer_name
  }))

  field_manager {
    force_conflicts = true
  }

  depends_on = [helm_release.argocd]
}

# =============================================================================
# App-of-Apps Setup (Optional)
# Creates: AppProject → Repository Secret → Root Application
# =============================================================================

# AppProjects - defines allowed sources and destinations
resource "kubectl_manifest" "argocd_project" {
  for_each = var.enabled ? { for p in var.projects : p.name => p } : {}

  yaml_body = templatefile("${path.module}/app-project.yaml", {
    project_name        = each.key
    namespace           = local.effective_namespace
    project_description = each.value.description
    repo_urls           = join("\n", [for url in each.value.repo_urls : "    - ${url}"])
    extra_destinations  = []
  })

  depends_on = [helm_release.argocd]
}

# Repository Secrets - credentials for private Git repos
resource "kubernetes_secret" "argocd_repo" {
  for_each = var.enabled ? { for repo in nonsensitive(var.repositories) : repo.name => repo } : {}

  metadata {
    name      = each.key
    namespace = local.effective_namespace
    labels = {
      "argocd.argoproj.io/secret-type" = "repository"
    }
  }

  data = {
    type     = "git"
    url      = each.value.url
    username = each.value.username
    password = each.value.password
  }

  depends_on = [helm_release.argocd]
}

# Root Application - the "app of apps" that deploys child apps
resource "kubectl_manifest" "argocd_root_app" {
  count = var.enabled && var.root_app_name != "" ? 1 : 0

  yaml_body = templatefile("${path.module}/app-rootapp.yaml", {
    app_name              = var.root_app_name
    namespace             = local.effective_namespace
    project_name          = var.root_app_project
    repo_url              = var.root_app_repo_url
    target_revision       = var.target_revision
    app_path              = var.app_path
    destination_namespace = var.destination_namespace
    helm_value_files      = var.helm_value_files
  })

  depends_on = [kubectl_manifest.argocd_project]
}

# =============================================================================
# Auto admin password — generated once, stored in Key Vault as plain text.
# bcrypt hash is frozen on first apply via terraform_data to prevent Helm drift.
# =============================================================================

resource "random_password" "admin" {
  count            = var.enabled ? 1 : 0
  length           = 20
  special          = true
  override_special = "!#$"
}

resource "terraform_data" "admin_bcrypt_hash" {
  count = var.enabled ? 1 : 0
  input = bcrypt(random_password.admin[0].result)

  lifecycle {
    ignore_changes = [input]
  }
}

data "azurerm_key_vault" "this" {
  count               = local.kv_enabled ? 1 : 0
  name                = var.aks_keyvault_name
  resource_group_name = var.resource_group_name
}

resource "azurerm_key_vault_secret" "admin_password" {
  count        = local.kv_enabled ? 1 : 0
  name         = "argocd-${var.env}-admin-password"
  value        = random_password.admin[0].result
  key_vault_id = data.azurerm_key_vault.this[0].id
}

# =============================================================================
# Azure AD groups for ArgoCD RBAC
# =============================================================================

resource "azuread_group" "admin" {
  count            = var.enabled && var.enable_sso ? 1 : 0
  display_name     = "grp-${var.project_name}-argocd-admin-${var.env}"
  security_enabled = true
  mail_enabled     = false
}

resource "azuread_group" "reader" {
  count            = var.enabled && var.enable_sso ? 1 : 0
  display_name     = "grp-${var.project_name}-argocd-reader-${var.env}"
  security_enabled = true
  mail_enabled     = false
}

# =============================================================================
# Azure AD App Registration for OIDC SSO
# Manual steps after apply:
#   1. Entra ID → Enterprise Apps → app-argocd-{project}-{env} → Users and groups
#      → add admin and reader AD groups
#   2. App Registrations → API permissions → Grant admin consent
# =============================================================================

resource "azuread_application" "argocd" {
  count        = var.enabled && var.enable_sso ? 1 : 0
  display_name = "app-argocd-${var.project_name}-${var.env}"

  identifier_uris = var.org_domain != "" ? [
    var.location_abbv != "" ? "api://${var.org_domain}/argocd-${var.env}-${var.location_abbv}" : "api://${var.org_domain}/argocd-${var.env}"
  ] : null
  sign_in_audience = "AzureADMyOrg"

  web {
    homepage_url  = "https://argocd.${var.dns_zone}"
    redirect_uris = ["https://argocd.${var.dns_zone}/auth/callback"]
    logout_url    = "https://argocd.${var.dns_zone}/login"

    implicit_grant {
      access_token_issuance_enabled = true
      id_token_issuance_enabled     = true
    }
  }

  required_resource_access {
    resource_app_id = "00000003-0000-0000-c000-000000000000" # Microsoft Graph

    resource_access {
      id   = "14dad69e-099b-42c9-810b-d002981feec1" # profile
      type = "Scope"
    }
    resource_access {
      id   = "e1fe6dd8-ba31-4d61-89e7-88639da4683d" # User.Read
      type = "Scope"
    }
    resource_access {
      id   = "37f7f235-527c-4136-accd-4a02d197296e" # openid
      type = "Scope"
    }
    resource_access {
      id   = "64a6cdd6-aab1-4aaf-94b8-3cc8405e90d0" # email
      type = "Scope"
    }
  }

  optional_claims {
    access_token { name = "groups" }
    id_token { name = "groups" }
    saml2_token { name = "groups" }
  }
}

resource "azuread_application_password" "argocd" {
  count          = var.enabled && var.enable_sso ? 1 : 0
  application_id = azuread_application.argocd[0].id
  display_name   = "terraform-generated"

  lifecycle {
    ignore_changes = [end_date]
  }
}

resource "azuread_service_principal" "argocd" {
  count     = var.enabled && var.enable_sso ? 1 : 0
  client_id = azuread_application.argocd[0].client_id
}

# =============================================================================
# ArgoCD ConfigMaps — argocd-cm (OIDC), argocd-rbac-cm, notifications
# =============================================================================

resource "kubectl_manifest" "argocd_cm" {
  count = var.enabled && var.enable_sso ? 1 : 0

  yaml_body = templatefile("${path.module}/argocd-cm.yaml", {
    namespace     = local.effective_namespace
    dns_zone      = var.dns_zone
    tenant_id     = var.tenant_id
    client_id     = azuread_application.argocd[0].client_id
    client_secret = azuread_application_password.argocd[0].value
  })

  depends_on = [helm_release.argocd]
}

resource "kubectl_manifest" "argocd_rbac_cm" {
  count = var.enabled && var.enable_sso ? 1 : 0

  yaml_body = templatefile("${path.module}/argocd-rbac-cm.yaml", {
    namespace      = local.effective_namespace
    admin_group_id = azuread_group.admin[0].object_id
  })

  depends_on = [helm_release.argocd]
}

resource "kubectl_manifest" "argocd_notifications_cm" {
  count = var.enabled && var.enable_sso ? 1 : 0

  yaml_body = templatefile("${path.module}/argocd-notifications-cm.yaml", {
    namespace = local.effective_namespace
  })

  depends_on = [helm_release.argocd]
}

resource "kubectl_manifest" "argocd_notifications_secret" {
  count = var.enabled && var.enable_sso ? 1 : 0

  yaml_body = templatefile("${path.module}/argocd-notifications-secret.yaml", {
    namespace = local.effective_namespace
  })

  depends_on = [helm_release.argocd]
}

# =============================================================================
# ADO repository secrets — reads devops-inc-pat from Key Vault
# PAT must have Code (Read) on the helmcharts repo.
# =============================================================================

data "azurerm_key_vault_secret" "devops_pat" {
  count        = var.enabled && var.ado_org_name != "" ? 1 : 0
  name         = "devops-inc-pat"
  key_vault_id = data.azurerm_key_vault.this[0].id
}

resource "kubectl_manifest" "argocd_repo_helmcharts" {
  count = var.enabled && var.ado_org_name != "" ? 1 : 0

  yaml_body = templatefile("${path.module}/app-repo.yaml", {
    repo_name     = "argocd-${var.project_name}-helm-${var.env}"
    namespace     = local.effective_namespace
    repo_url      = "https://dev.azure.com/${var.ado_org_name}/DevOps/_git/helmcharts"
    repo_password = data.azurerm_key_vault_secret.devops_pat[0].value
    repo_username = "pat"
  })

  depends_on = [helm_release.argocd]
}

# =============================================================================
# GitHub repository credential template
# One repo-creds secret covers every repo under the GitHub org URL prefix.
# Prerequisite: create the KV secret before applying:
#   az keyvault secret set --vault-name <kv> --name github-pat --value <PAT>
# PAT requires: repo (read) scope for private repos.
# =============================================================================

resource "kubectl_manifest" "argocd_github_repo_creds" {
  count = var.enabled && var.github_org_url != "" ? 1 : 0

  yaml_body = templatefile("${path.module}/github-repo-creds.yaml", {
    org_name  = lower(replace(replace(var.github_org_url, "https://github.com/", ""), "/", "-"))
    namespace = local.effective_namespace
    org_url   = var.github_org_url
    pat       = var.github_pat_value
  })

  depends_on = [helm_release.argocd]
}

# =============================================================================
# Instance-based AppProject and Root App (argocd_instances_config pattern)
# Creates one AppProject + root Application per entry in argocd_instances_config.
# =============================================================================

resource "kubectl_manifest" "argocd_instance_project" {
  for_each = var.enabled ? var.argocd_instances_config : {}

  yaml_body = templatefile("${path.module}/app-project.yaml", {
    project_name        = "${var.project_name}-${each.key}"
    namespace           = local.effective_namespace
    project_description = "ArgoCD AppProject for ${var.project_name} ${each.key}"
    repo_urls = length(var.argocd_project_source_repos) > 0 ? join("\n", [
      for r in var.argocd_project_source_repos : "    - ${r}"
      ]) : join("\n", [
      "    - https://dev.azure.com/${var.ado_org_name}/DevOps/_git/helmcharts",
    ])
    extra_destinations = [
      for u in [each.value.cluster_url] : u
      if u != "" && u != "https://kubernetes.default.svc"
    ]
  })

  depends_on = [helm_release.argocd]
}

resource "kubectl_manifest" "argocd_instance_rootapp" {
  for_each = var.enabled ? var.argocd_instances_config : {}

  yaml_body = templatefile("${path.module}/app-rootapp.yaml", {
    app_name              = "root-app-${var.project_name}-${each.key}"
    namespace             = local.effective_namespace
    project_name          = "${var.project_name}-${each.key}"
    repo_url              = local.effective_config_repo_url
    target_revision       = each.key == "prod" ? "main" : "delivery"
    app_path              = "charts/apps"
    destination_namespace = "default"
    helm_value_files      = ["values-${each.key}.yaml"]
  })

  depends_on = [kubectl_manifest.argocd_instance_project]
}
