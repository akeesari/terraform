data "azurerm_client_config" "current" {}

# ==============================================================================
# Key Vault
# ==============================================================================
resource "azurerm_key_vault" "this" {
  name                       = var.name
  location                   = var.location
  resource_group_name        = var.resource_group_name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = var.sku_name
  rbac_authorization_enabled = true # Use RBAC instead of legacy access policies
  soft_delete_retention_days = var.soft_delete_retention_days
  purge_protection_enabled   = var.purge_protection_enabled
  tags                       = var.tags

  enabled_for_disk_encryption = var.enable_disk_encryption

  # Deny all public network access by default.
  # AKS pods and App Service reach Key Vault via Private Endpoint (snet-data)
  # or via the AzureServices bypass until a PE is provisioned.
  network_acls {
    default_action             = var.enable_private_endpoints ? "Deny" : "Allow"
    bypass                     = "AzureServices"
    ip_rules                   = var.ip_rules
    virtual_network_subnet_ids = var.allowed_subnet_ids
  }

  lifecycle {
    precondition {
      condition     = var.enable_private_endpoints || length(var.ip_rules) > 0 || length(var.allowed_subnet_ids) > 0 || var.allow_unrestricted_network_access
      error_message = "Key Vault would be fully open to the internet: enable_private_endpoints = false, ip_rules = [], and allowed_subnet_ids = []. Either set enable_private_endpoints = true, provide ip_rules, or set allow_unrestricted_network_access = true to explicitly acknowledge open dev access."
    }
    ignore_changes = [tags["CreatedDate"], tags["LastModified"]]
  }
}

# ==============================================================================
# Management Lock (prod only)
# ==============================================================================
resource "azurerm_management_lock" "this" {
  count      = var.enable_management_lock ? 1 : 0
  name       = "protect-kv"
  scope      = azurerm_key_vault.this.id
  lock_level = "CanNotDelete"
  notes      = "Protects Key Vault from accidental deletion. Remove this lock before running terraform destroy."
}

# ==============================================================================
# Private Endpoint
# ==============================================================================
resource "azurerm_private_endpoint" "this" {
  count               = var.enable_private_endpoints && var.private_endpoint_subnet_id != null ? 1 : 0
  name                = "${var.name}-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "${var.name}-psc"
    private_connection_resource_id = azurerm_key_vault.this.id
    is_manual_connection           = false
    subresource_names              = ["vault"]
  }

  dynamic "private_dns_zone_group" {
    for_each = var.key_vault_dns_zone_id != null ? [1] : []
    content {
      name                 = "${var.name}-dns-zone-group"
      private_dns_zone_ids = [var.key_vault_dns_zone_id]
    }
  }

  lifecycle {
    ignore_changes = [tags["CreatedDate"], tags["LastModified"]]
  }
}

# ==============================================================================
# Customer-Managed Keys (CMK)
# ==============================================================================
resource "azurerm_key_vault_key" "postgres_cmk" {
  count        = var.enable_postgres_cmk ? 1 : 0
  name         = "cmk-postgres"
  key_vault_id = azurerm_key_vault.this.id
  key_type     = "RSA"
  key_size     = 4096
  key_opts     = ["decrypt", "encrypt", "sign", "unwrapKey", "verify", "wrapKey"]
  tags         = var.tags
  depends_on   = [azurerm_key_vault.this]
}

resource "azurerm_key_vault_key" "storage_cmk" {
  count        = var.enable_storage_cmk ? 1 : 0
  name         = "cmk-storage"
  key_vault_id = azurerm_key_vault.this.id
  key_type     = "RSA"
  key_size     = 4096
  key_opts     = ["decrypt", "encrypt", "sign", "unwrapKey", "verify", "wrapKey"]
  tags         = var.tags
  depends_on   = [azurerm_key_vault.this]
}

# ==============================================================================
# RBAC Role Assignments
# ==============================================================================

# Grant the Terraform caller Key Vault Administrator (initial setup)
resource "azurerm_role_assignment" "terraform_admin" {
  count                = var.grant_terraform_admin ? 1 : 0
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = coalesce(var.terraform_principal_id, data.azurerm_client_config.current.object_id)
  depends_on           = [azurerm_key_vault.this]
  lifecycle { ignore_changes = [principal_id] }
}

# Grant named users / service principals Key Vault Secrets Officer
resource "azurerm_role_assignment" "user_secrets_officer" {
  for_each             = toset(var.user_principal_ids)
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = each.value
  depends_on           = [azurerm_key_vault.this]
}

# Grant PostgreSQL managed identity Crypto Service Encryption User (for CMK)
resource "azurerm_role_assignment" "postgres_crypto_user" {
  count                = var.enable_postgres_cmk && var.postgres_identity_principal_id != null ? 1 : 0
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Crypto Service Encryption User"
  principal_id         = var.postgres_identity_principal_id
  depends_on           = [azurerm_key_vault.this, azurerm_key_vault_key.postgres_cmk]
}

# Grant Storage Account managed identity Crypto Service Encryption User (for CMK)
resource "azurerm_role_assignment" "storage_crypto_user" {
  count                = var.enable_storage_cmk && var.storage_identity_principal_id != null ? 1 : 0
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Crypto Service Encryption User"
  principal_id         = var.storage_identity_principal_id
  depends_on           = [azurerm_key_vault.this, azurerm_key_vault_key.storage_cmk]
}

# Grant AKS Key Vault Secrets Provider identity access to read secrets (CSI driver)
resource "azurerm_role_assignment" "aks_secrets_user" {
  count                = var.enable_aks_connection && var.aks_secrets_provider_identity_id != null ? 1 : 0
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = var.aks_secrets_provider_identity_id
  depends_on           = [azurerm_key_vault.this]
}

# ==============================================================================
# Diagnostic Settings
# ==============================================================================
resource "azurerm_monitor_diagnostic_setting" "this" {
  count                      = var.enable_diagnostic_settings && var.log_analytics_workspace_id != null ? 1 : 0
  name                       = "${var.name}-diagnostics"
  target_resource_id         = azurerm_key_vault.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log { category = "AuditEvent" }
  enabled_log { category = "AzurePolicyEvaluationDetails" }
  enabled_metric { category = "AllMetrics" }
}
