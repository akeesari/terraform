locals {
  # Build the application_stack attributes: only the selected runtime is non-null;
  # all others are null so the provider ignores them.
  app_stack = {
    python_version          = var.runtime_stack == "python" ? var.runtime_version : null
    node_version            = var.runtime_stack == "node" ? var.runtime_version : null
    dotnet_version          = var.runtime_stack == "dotnet" ? var.runtime_version : null
    java_version            = var.runtime_stack == "java" ? var.runtime_version : null
    powershell_core_version = var.runtime_stack == "powershell" ? var.runtime_version : null
  }
}

# ==============================================================================
# Service Plan
# ==============================================================================
resource "azurerm_service_plan" "this" {
  name                = "${var.name}-plan"
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = "Linux"
  sku_name            = var.sku_name
  tags                = var.tags

  lifecycle {
    ignore_changes = [tags["CreatedDate"], tags["LastModified"]]
  }
}

# ==============================================================================
# Backing Storage Account
# The Functions runtime requires a dedicated storage account for triggers,
# host state, and deployment artifacts.  Entra-only auth is used via the
# function app's system-assigned managed identity — no access keys stored.
# ==============================================================================
resource "azurerm_storage_account" "this" {
  name                            = var.storage_account_name
  resource_group_name             = var.resource_group_name
  location                        = var.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  https_traffic_only_enabled      = true
  tags                            = var.tags

  # Deny all public network access; AzureServices bypass allows the Functions
  # runtime, Blob triggers, and Key Vault references to continue working.
  # Logging and Metrics allow Azure Monitor to collect storage metrics.
  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices", "Logging", "Metrics"]
  }

  lifecycle {
    ignore_changes = [tags["CreatedDate"], tags["LastModified"]]
  }
}

# ==============================================================================
# Function App
# ==============================================================================
resource "azurerm_linux_function_app" "this" {
  name                          = var.name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  service_plan_id               = azurerm_service_plan.this.id
  storage_account_name          = azurerm_storage_account.this.name
  storage_uses_managed_identity = true # Entra-only; no storage access keys in config
  https_only                    = true
  tags                          = var.tags

  identity {
    type = "SystemAssigned"
  }

  site_config {
    application_stack {
      python_version          = local.app_stack.python_version
      node_version            = local.app_stack.node_version
      dotnet_version          = local.app_stack.dotnet_version
      java_version            = local.app_stack.java_version
      powershell_core_version = local.app_stack.powershell_core_version
    }
  }

  app_settings = merge(var.app_settings, {
    APPLICATIONINSIGHTS_CONNECTION_STRING = var.app_insights_connection_string
    FUNCTIONS_EXTENSION_VERSION           = var.functions_extension_version
  })

  lifecycle {
    ignore_changes = [tags["CreatedDate"], tags["LastModified"]]
  }
}

# ==============================================================================
# Storage Role Assignments
# Required for storage_uses_managed_identity = true so the Functions runtime
# can read/write blobs, queues, and tables used by triggers and bindings.
# ==============================================================================
resource "azurerm_role_assignment" "storage_blob_owner" {
  scope                = azurerm_storage_account.this.id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = azurerm_linux_function_app.this.identity[0].principal_id
}

resource "azurerm_role_assignment" "storage_queue_contributor" {
  scope                = azurerm_storage_account.this.id
  role_definition_name = "Storage Queue Data Contributor"
  principal_id         = azurerm_linux_function_app.this.identity[0].principal_id
}

resource "azurerm_role_assignment" "storage_table_contributor" {
  scope                = azurerm_storage_account.this.id
  role_definition_name = "Storage Table Data Contributor"
  principal_id         = azurerm_linux_function_app.this.identity[0].principal_id
}
