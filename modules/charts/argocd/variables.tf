# ArgoCD Module Variables

variable "admin_password_hash" {
  description = "Bcrypt hash of the ArgoCD admin password. When set, overrides the auto-generated argocd-initial-admin-secret."
  type        = string
  default     = ""
  sensitive   = true
}

variable "enabled" {
  description = "Enable ArgoCD deployment"
  type        = bool
  default     = true
}

variable "release_name" {
  description = "Helm release name"
  type        = string
  default     = "argocd"
}

variable "namespace" {
  description = "Kubernetes namespace for ArgoCD"
  type        = string
  default     = "argocd"
}

variable "create_namespace" {
  description = "Create the namespace if it doesn't exist"
  type        = bool
  default     = true
}

variable "chart_version" {
  description = "ArgoCD Helm chart version"
  type        = string
  default     = "7.3.0"
}

variable "timeout" {
  description = "Helm release timeout in seconds"
  type        = number
  default     = 600
}

variable "additional_set_values" {
  description = "Additional Helm set values"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

# Ingress Configuration
variable "ingress_hostname" {
  description = "Hostname for ArgoCD ingress (e.g., argocd.dev.example.com). Ingress auto-enabled when set."
  type        = string
  default     = ""
}

variable "ingress_class_name" {
  description = "Ingress class name (e.g., nginx)"
  type        = string
  default     = "nginx"
}

variable "cluster_issuer_name" {
  description = "cert-manager ClusterIssuer name for TLS certificates"
  type        = string
  default     = "letsencrypt-prod"
}

# =============================================================================
# App-of-Apps Configuration
# =============================================================================

variable "projects" {
  description = "List of ArgoCD AppProjects to create"
  type = list(object({
    name        = string
    description = string
    repo_urls   = list(string)
  }))
  default = []
}

variable "repositories" {
  description = "List of Git repositories with credentials for ArgoCD"
  sensitive   = true
  type = list(object({
    name     = string
    url      = string
    username = string
    password = string
  }))
  default = []
}

variable "root_app_name" {
  description = "Name of the root application (app-of-apps)"
  type        = string
  default     = ""
}

variable "root_app_project" {
  description = "ArgoCD project for the root application"
  type        = string
  default     = ""
}

variable "root_app_repo_url" {
  description = "Git repository URL for the root application"
  type        = string
  default     = ""
}

variable "target_revision" {
  description = "Git branch/tag/commit to track"
  type        = string
  default     = "main"
}

variable "app_path" {
  description = "Path in repo containing Application manifests or Helm chart"
  type        = string
  default     = ""
}

variable "destination_namespace" {
  description = "Default namespace for deployed applications"
  type        = string
  default     = ""
}

variable "helm_value_files" {
  description = "List of Helm values files to use (e.g., ['values.yaml', 'values-dev.yaml'])"
  type        = list(string)
  default     = []
}

variable "tolerate_system_taints" {
  type        = bool
  description = "Deprecated. Use schedule_on_system_nodes instead."
  default     = null
}

variable "schedule_on_system_nodes" {
  type        = bool
  description = "Pin all pods to the system node pool (nodeSelector kubernetes.azure.com/mode=system + CriticalAddonsOnly toleration). Set false to run on user nodes."
  default     = true
}

# =============================================================================
# Full ArgoCD stack — SSO, auto password, ADO repos, metrics
# =============================================================================

variable "env" {
  description = "Environment name (e.g. dev, prod). Sets namespace to argocd-{env} and is used in resource names."
  type        = string
  default     = ""
}

variable "location_abbv" {
  description = "Optional location suffix appended to the App Registration identifier URI (e.g. wus → api://{org_domain}/argocd-{env}-wus). Leave empty to omit the suffix."
  type        = string
  default     = ""
}

variable "dns_zone" {
  description = "DNS zone for the ArgoCD URL and OIDC redirect URIs (e.g. wealthyminds.ai)."
  type        = string
  default     = ""
}

variable "project_name" {
  description = "Project name used in AD group display names and AppProject naming (e.g. wealthyminds)."
  type        = string
  default     = ""
}

variable "aks_keyvault_name" {
  description = "Key Vault name used to store the auto-generated admin password and to read the DevOps PAT secret."
  type        = string
  default     = ""
}

variable "resource_group_name" {
  description = "Resource group containing the Key Vault (required when aks_keyvault_name is set)."
  type        = string
  default     = ""
}

variable "tenant_id" {
  description = "Azure AD tenant ID used in the OIDC issuer URL."
  type        = string
  default     = ""
}

variable "org_domain" {
  description = "Organisation domain used in the Azure AD App Registration identifier URI (e.g. contoso.com). When empty, no identifier URI is set."
  type        = string
  default     = ""
}

variable "argocd_config_repo_url" {
  description = "Git repo URL for the ArgoCD config (App-of-Apps source). When empty: falls back to the ADO argocd repo (requires ado_org_name) or the first entry of argocd_project_source_repos."
  type        = string
  default     = ""
}

variable "ado_org_name" {
  description = "Azure DevOps organisation name used in repository secret URLs (https://dev.azure.com/{ado_org_name}/DevOps/_git/...). Non-empty enables ADO repo secret creation."
  type        = string
  default     = ""
}

variable "argocd_project_source_repos" {
  description = "Source repos allowed in the AppProject. Defaults to the three ADO repos when empty and ado_org_name is set; set explicitly for GitHub-hosted repos (or use [\"*\"] to allow any repo)."
  type        = list(string)
  default     = []
}

variable "argocd_instances_config" {
  description = "Per-instance config driving AppProject destinations and root app creation. Key is the instance identifier (e.g. 'dev'). cluster_url is the Kubernetes API server URL for this instance."
  type = map(object({
    cluster_url = string
  }))
  default = {}
}

variable "enable_sso" {
  description = "Create Azure AD App Registration, AD groups, and argocd-cm / argocd-rbac-cm / notifications ConfigMaps for OIDC SSO. Requires dns_zone, tenant_id, project_name, env."
  type        = bool
  default     = false
}

variable "github_org_url" {
  description = "GitHub org URL prefix for the ArgoCD credential template (e.g. https://github.com/NovusMinds-AI). Covers all repos in this org automatically."
  type        = string
  default     = ""
}

variable "github_pat_value" {
  description = "GitHub PAT value (sensitive). Injected directly — the stack is responsible for storing it in Key Vault via azurerm_key_vault_secret."
  type        = string
  default     = ""
  sensitive   = true
}

