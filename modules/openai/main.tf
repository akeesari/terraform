# ==============================================================================
# Azure OpenAI Account
# ==============================================================================
resource "azurerm_cognitive_account" "this" {
  name                          = var.name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  kind                          = "OpenAI"
  sku_name                      = var.sku_name
  custom_subdomain_name         = var.custom_subdomain_name
  public_network_access_enabled = var.public_network_access_enabled
  local_auth_enabled            = var.local_auth_enabled
  tags                          = var.tags

  # Production gate — prevent accidental deletion of the account and all deployments.
  lifecycle {
    ignore_changes = [tags["CreatedDate"], tags["LastModified"]]
  }
}

# ==============================================================================
# Model Deployments (GPT-4o, embeddings, etc.)
# Dynamic — driven by var.deployments map; add entries without touching main.tf.
# ==============================================================================
resource "azurerm_cognitive_deployment" "this" {
  for_each = var.deployments

  name                 = each.key
  cognitive_account_id = azurerm_cognitive_account.this.id

  model {
    format  = "OpenAI"
    name    = each.value.model_name
    version = each.value.model_version
  }

  sku {
    name     = each.value.sku_name
    capacity = each.value.capacity
  }
}

# ==============================================================================
# Management Lock (prod only)
# ==============================================================================
resource "azurerm_management_lock" "this" {
  count      = var.enable_management_lock ? 1 : 0
  name       = "protect-oai"
  scope      = azurerm_cognitive_account.this.id
  lock_level = "CanNotDelete"
  notes      = "Protects Azure OpenAI from accidental deletion. Remove this lock before running terraform destroy."
}
