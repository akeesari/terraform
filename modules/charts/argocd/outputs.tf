# ArgoCD Module Outputs

output "namespace" {
  description = "ArgoCD namespace"
  value       = var.namespace
}

output "release_name" {
  description = "Helm release name"
  value       = var.enabled ? helm_release.argocd[0].name : null
}

output "chart_version" {
  description = "Deployed chart version"
  value       = var.enabled ? helm_release.argocd[0].version : null
}

output "server_service" {
  description = "ArgoCD server service name"
  value       = var.enabled ? "${var.release_name}-server" : null
}

output "ingress_hostname" {
  description = "ArgoCD ingress hostname"
  value       = var.enabled && var.ingress_hostname != "" ? var.ingress_hostname : null
}

output "ingress_url" {
  description = "ArgoCD URL (HTTPS)"
  value       = var.enabled && var.ingress_hostname != "" ? "https://${var.ingress_hostname}" : null
}

output "argocd_url" {
  description = "ArgoCD UI URL derived from dns_zone (set when enable_sso = true)"
  value       = var.enabled && var.enable_sso && var.dns_zone != "" ? "https://argocd.${var.dns_zone}" : null
}

output "admin_group_id" {
  description = "Object ID of the ArgoCD admin AD group"
  value       = var.enabled && var.enable_sso ? azuread_group.admin[0].object_id : null
}

output "reader_group_id" {
  description = "Object ID of the ArgoCD reader AD group"
  value       = var.enabled && var.enable_sso ? azuread_group.reader[0].object_id : null
}

output "app_registration_client_id" {
  description = "Client ID of the ArgoCD Azure AD App Registration"
  value       = var.enabled && var.enable_sso ? azuread_application.argocd[0].client_id : null
}

output "admin_password_kv_secret_name" {
  description = "Key Vault secret name holding the ArgoCD admin password"
  value       = local.kv_enabled ? azurerm_key_vault_secret.admin_password[0].name : null
}
