# ==============================================================================
# Storage Account
# ==============================================================================
resource "azurerm_storage_account" "this" {
  count                           = var.enable_storage ? 1 : 0
  name                            = var.name
  resource_group_name             = var.resource_group_name
  location                        = var.location
  account_tier                    = var.account_tier
  account_replication_type        = var.replication_type
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false # Disable anonymous blob access
  https_traffic_only_enabled      = true
  is_hns_enabled                  = var.enable_hierarchical_namespace
  tags                            = var.tags

  blob_properties {
    delete_retention_policy {
      days = 7
    }
    container_delete_retention_policy {
      days = 7
    }
  }

  # Deny all public network access; allow Trusted Microsoft Services so
  # Azure Backup, Monitor, and Key Vault can still reach the account.
  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices", "Logging", "Metrics"]
  }

  lifecycle {
    ignore_changes = [tags["CreatedDate"], tags["LastModified"]]
  }
}

# ==============================================================================
# Blob Containers
# ==============================================================================
resource "azurerm_storage_container" "this" {
  for_each = var.enable_storage ? toset(var.containers) : toset([])

  name                  = each.key
  storage_account_id    = azurerm_storage_account.this[0].id
  container_access_type = "private"
}

# ==============================================================================
# Storage Queues
# ==============================================================================
resource "azurerm_storage_queue" "this" {
  for_each = var.enable_storage ? toset(var.queues) : toset([])

  name                 = each.key
  storage_account_name = azurerm_storage_account.this[0].name
}

# ==============================================================================
# Lifecycle Management Policy
# ==============================================================================
resource "azurerm_storage_management_policy" "this" {
  count              = var.enable_storage ? 1 : 0
  storage_account_id = azurerm_storage_account.this[0].id

  rule {
    name    = "tier-to-cool"
    enabled = true

    filters {
      blob_types = ["blockBlob"]
    }

    actions {
      base_blob {
        tier_to_cool_after_days_since_modification_greater_than = var.tier_to_cool_after_days
      }
    }
  }
}
