output "id" {
  description = "AKS cluster resource ID."
  value       = try(azurerm_kubernetes_cluster.this[0].id, null)
}

output "name" {
  description = "AKS cluster name."
  value       = try(azurerm_kubernetes_cluster.this[0].name, null)
}

output "kube_config_raw" {
  description = "Raw kubeconfig for the AKS cluster."
  value       = try(azurerm_kubernetes_cluster.this[0].kube_config_raw, null)
  sensitive   = true
}

output "kubelet_identity" {
  description = "Kubelet managed identity block (object_id, client_id, user_assigned_identity_id)."
  value       = try(azurerm_kubernetes_cluster.this[0].kubelet_identity[0], null)
}

output "oidc_issuer_url" {
  description = "OIDC issuer URL — required to configure workload identity federated credentials."
  value       = try(azurerm_kubernetes_cluster.this[0].oidc_issuer_url, null)
}

output "fqdn" {
  description = "Public FQDN of the AKS API server."
  value       = try(azurerm_kubernetes_cluster.this[0].fqdn, null)
}

output "private_fqdn" {
  description = "Private FQDN of the AKS API server (set when enable_private_cluster = true)."
  value       = try(azurerm_kubernetes_cluster.this[0].private_fqdn, null)
}

output "node_resource_group" {
  description = "Name of the auto-created resource group that holds AKS node VMs and disks."
  value       = try(azurerm_kubernetes_cluster.this[0].node_resource_group, null)
}

output "node_resource_group_id" {
  description = "Resource ID of the auto-created node resource group."
  value       = try(azurerm_kubernetes_cluster.this[0].node_resource_group_id, null)
}

output "principal_id" {
  description = "Principal ID of the cluster managed identity (system or user-assigned)."
  value       = local.aks_identity_principal_id
}

output "user_assigned_identity_id" {
  description = "Resource ID of the user-assigned managed identity (null when using SystemAssigned)."
  value       = try(azurerm_user_assigned_identity.aks[0].id, null)
}

output "user_assigned_identity_client_id" {
  description = "Client ID of the user-assigned managed identity."
  value       = try(azurerm_user_assigned_identity.aks[0].client_id, null)
}

output "key_vault_secrets_provider" {
  description = "Key Vault Secrets Provider configuration block."
  value       = try(azurerm_kubernetes_cluster.this[0].key_vault_secrets_provider[0], null)
}

output "web_app_routing_identity" {
  description = "Web App Routing managed identity (object_id, client_id, user_assigned_identity_id)."
  value       = try(azurerm_kubernetes_cluster.this[0].web_app_routing[0].web_app_routing_identity[0], null)
}
