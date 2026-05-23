output "id" {
  description = "AI Foundry account resource ID."
  value       = azapi_resource.ai_foundry.id
}

output "name" {
  description = "AI Foundry account name."
  value       = azapi_resource.ai_foundry.name
}

output "ai_foundry_endpoint" {
  description = "API endpoint URL for the AI Foundry account."
  value       = try(azapi_resource.ai_foundry.output.properties.endpoint, null)
}

output "ai_foundry_principal_id" {
  description = "Principal ID of the AI Foundry account system-assigned managed identity."
  value       = try(azapi_resource.ai_foundry.output.identity.principalId, null)
}

output "project_id" {
  description = "AI Foundry project resource ID."
  value       = azapi_resource.ai_foundry_project.id
}

output "project_name" {
  description = "AI Foundry project name."
  value       = azapi_resource.ai_foundry_project.name
}

output "project_principal_id" {
  description = "Principal ID of the AI Foundry project managed identity."
  value       = try(azapi_resource.ai_foundry_project.output.identity.principalId, null)
}

output "project_internal_id" {
  description = "Internal ID of the AI Foundry project."
  value       = try(azapi_resource.ai_foundry_project.output.properties.internalId, null)
}

output "model_deployments" {
  description = "Map of all deployed models with their resource IDs and endpoint URLs."
  value = merge(
    {
      for key, model in azurerm_cognitive_deployment.openai_models : key => {
        id       = model.id
        name     = model.name
        endpoint = "${try(azapi_resource.ai_foundry.output.properties.endpoint, "")}openai/deployments/${model.name}"
      }
    },
    {
      for key, model in azapi_resource.anthropic_models : key => {
        id       = model.id
        name     = model.name
        endpoint = "${try(azapi_resource.ai_foundry.output.properties.endpoint, "")}anthropic/deployments/${model.name}"
      }
    }
  )
}

output "storage_account_id" {
  description = "Storage account resource ID."
  value       = var.create_storage_account ? azurerm_storage_account.foundry_storage[0].id : null
}

output "storage_account_name" {
  description = "Storage account name."
  value       = var.create_storage_account ? azurerm_storage_account.foundry_storage[0].name : null
}

output "ai_search_id" {
  description = "AI Search service resource ID."
  value       = var.create_ai_search ? azapi_resource.ai_search[0].id : null
}

output "ai_search_endpoint" {
  description = "AI Search service endpoint URL."
  value       = var.create_ai_search ? "https://${azapi_resource.ai_search[0].name}.search.windows.net/" : null
}

output "ai_search_principal_id" {
  description = "Principal ID of the AI Search service managed identity."
  value       = var.create_ai_search ? try(azapi_resource.ai_search[0].output.identity.principalId, null) : null
}
