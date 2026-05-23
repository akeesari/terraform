data "azurerm_client_config" "current" {}

resource "azurerm_mssql_server" "this" {
  count               = var.enable_sql_server ? 1 : 0
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  version             = var.sql_version
  tags                = var.tags

  # SQL authentication (disabled when Azure AD only)
  administrator_login          = var.azuread_authentication_only ? null : var.administrator_login
  administrator_login_password = var.azuread_authentication_only ? null : var.administrator_login_password

  # Security
  minimum_tls_version           = "1.2"
  public_network_access_enabled = var.public_network_access_enabled

  # Azure AD authentication
  dynamic "azuread_administrator" {
    for_each = var.azuread_admin_login != null ? [1] : []
    content {
      login_username              = var.azuread_admin_login
      object_id                   = var.azuread_admin_object_id
      tenant_id                   = coalesce(var.azuread_admin_tenant_id, data.azurerm_client_config.current.tenant_id)
      azuread_authentication_only = var.azuread_authentication_only
    }
  }

  lifecycle {
    ignore_changes = [
      tags["CreatedDate"],
      tags["LastModified"],
      administrator_login_password
    ]
  }
}

# Allow Azure services to access the server (0.0.0.0 – 0.0.0.0 special rule)
resource "azurerm_mssql_firewall_rule" "allow_azure_services" {
  count            = var.enable_sql_server && var.allow_azure_services ? 1 : 0
  name             = "AllowAzureServices"
  server_id        = azurerm_mssql_server.this[0].id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# Custom firewall rules
resource "azurerm_mssql_firewall_rule" "custom" {
  for_each         = var.enable_sql_server ? { for rule in var.firewall_rules : rule.name => rule } : {}
  name             = each.value.name
  server_id        = azurerm_mssql_server.this[0].id
  start_ip_address = each.value.start_ip_address
  end_ip_address   = each.value.end_ip_address
}

resource "azurerm_mssql_database" "this" {
  for_each    = var.enable_sql_server ? { for db in var.databases : db.name => db } : {}
  name        = each.value.name
  server_id   = azurerm_mssql_server.this[0].id
  sku_name    = each.value.sku_name
  max_size_gb = each.value.max_size_gb
  collation   = each.value.collation

  zone_redundant = each.value.zone_redundant

  # Transparent Data Encryption is always on
  transparent_data_encryption_enabled = true

  tags = var.tags

  lifecycle {
    ignore_changes = [tags["CreatedDate"], tags["LastModified"]]
  }
}
