# =============================================================================
# pgAdmin Module Outputs
# =============================================================================

output "namespace" {
  description = "Kubernetes namespace where pgAdmin is deployed."
  value       = var.enabled ? kubernetes_namespace.pgadmin[0].metadata[0].name : null
}

output "release_name" {
  description = "Helm release name for pgAdmin."
  value       = var.enabled ? helm_release.pgadmin[0].name : null
}

output "url" {
  description = "pgAdmin HTTPS URL."
  value       = var.enabled && var.ingress_hostname != "" ? "https://${var.ingress_hostname}" : null
}

output "admin_email" {
  description = "pgAdmin admin login email."
  value       = var.enabled ? var.admin_email : null
}
