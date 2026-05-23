output "cert_manager_namespace" {
  description = "Namespace where cert-manager is deployed"
  value       = var.namespace
}

output "cert_manager_release_name" {
  description = "Helm release name of cert-manager"
  value       = var.release_name
}

