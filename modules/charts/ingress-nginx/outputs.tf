output "ingress_namespace" {
  description = "Namespace where ingress-nginx is deployed"
  value       = var.namespace
}

output "ingress_release_name" {
  description = "Helm release name of ingress-nginx"
  value       = var.release_name
}
