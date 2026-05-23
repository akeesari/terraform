output "id" {
  description = "Resource ID of the bootstrap resource group (primary resource)"
  value       = azurerm_resource_group.this.id
}

output "name" {
  description = "Name of the bootstrap resource group"
  value       = azurerm_resource_group.this.name
}

output "resource_group_name" {
  description = "Name of the bootstrap resource group"
  value       = azurerm_resource_group.this.name
}

output "storage_account_name" {
  description = "Name of the storage account holding Terraform remote state files"
  value       = azurerm_storage_account.this.name
}

output "storage_container_name" {
  description = "Name of the blob container for Terraform state files"
  value       = azurerm_storage_container.this.name
}

output "key_vault_name" {
  description = "Name of the Key Vault storing Terraform credentials"
  value       = azurerm_key_vault.this.name
}

output "key_vault_uri" {
  description = "URI of the Key Vault (use in scripts that read secrets)"
  value       = azurerm_key_vault.this.vault_uri
}

output "service_principal_client_id" {
  description = "Client ID (App ID) of the Terraform automation Service Principal"
  value       = azuread_application.terraform.client_id
}

output "service_principal_object_id" {
  description = "Object ID of the Terraform automation Service Principal"
  value       = azuread_service_principal.terraform.object_id
}

output "backend_config_snippet" {
  description = "Ready-to-paste backend block for all other Terraform stacks in this project. Replace <stack-name> with a unique key per stack (e.g. wealthyminds.tfstate)."
  value       = <<-EOT

    terraform {
      backend "azurerm" {
        resource_group_name  = "${azurerm_resource_group.this.name}"
        storage_account_name = "${azurerm_storage_account.this.name}"
        container_name       = "${azurerm_storage_container.this.name}"
        key                  = "<stack-name>.tfstate"
        # Authenticate via ARM_ACCESS_KEY env var (value = tf-access-key secret in Key Vault)
        # OR via ARM_CLIENT_ID + ARM_CLIENT_SECRET + ARM_TENANT_ID + ARM_SUBSCRIPTION_ID
      }
    }

  EOT
}
