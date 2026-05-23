output "namespace" {
  description = "Namespace where prometheus-operator-crds are deployed"
  value       = var.enabled ? kubernetes_namespace.prometheus_crds[0].metadata[0].name : null
}

output "release_name" {
  description = "Helm release name of prometheus-operator-crds"
  value       = var.enabled ? helm_release.prometheus_crds[0].name : null
}
