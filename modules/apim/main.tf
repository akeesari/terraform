data "azurerm_client_config" "current" {}

# ==============================================================================
# API Management Service
# ==============================================================================
resource "azurerm_api_management" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  publisher_name      = var.publisher_name
  publisher_email     = var.publisher_email
  sku_name            = var.sku_name
  min_api_version     = var.min_api_version

  # System-assigned identity allows APIM to pull certificates from Key Vault
  # and call backends authenticated with Managed Identity.
  identity {
    type = "SystemAssigned"
  }

  # VNet integration: set virtual_network_type to "External" or "Internal" and
  # supply subnet_id. "None" (default) deploys with a public endpoint only.
  virtual_network_type = var.virtual_network_type

  dynamic "virtual_network_configuration" {
    for_each = var.virtual_network_type != "None" && var.subnet_id != null ? [1] : []
    content {
      subnet_id = var.subnet_id
    }
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [tags["CreatedDate"], tags["LastModified"]]
  }
}

# ==============================================================================
# Application Insights Logger
# Wires APIM to App Insights so each API request is traced end-to-end.
# Pass the App Insights resource ID and instrumentation key from the
# monitoring module outputs.
# ==============================================================================
resource "azurerm_api_management_logger" "this" {
  count               = var.app_insights_id != null && var.app_insights_instrumentation_key != null ? 1 : 0
  name                = "${var.name}-logger"
  api_management_name = azurerm_api_management.this.name
  resource_group_name = var.resource_group_name
  resource_id         = var.app_insights_id

  application_insights {
    instrumentation_key = var.app_insights_instrumentation_key
  }
}

# ==============================================================================
# Diagnostic Settings → Log Analytics
# ==============================================================================
resource "azurerm_monitor_diagnostic_setting" "this" {
  count                      = var.log_analytics_workspace_id != null ? 1 : 0
  name                       = "diag-${var.name}"
  target_resource_id         = azurerm_api_management.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  # GatewayLogs: every inbound/outbound API request logged at the gateway layer.
  enabled_log {
    category = "GatewayLogs"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

# ==============================================================================
# Named Values
# Key-value pairs accessible inside APIM policies via {{name}} syntax.
# For secrets, set secret = true — the value is stored as a Key Vault reference
# or masked in the portal.
# ==============================================================================
resource "azurerm_api_management_named_value" "this" {
  for_each = { for nv in var.named_values : nv.name => nv }

  name                = each.key
  display_name        = each.value.display_name
  value               = each.value.value
  secret              = each.value.secret
  api_management_name = azurerm_api_management.this.name
  resource_group_name = var.resource_group_name
}

# ==============================================================================
# Management Lock
# ==============================================================================
resource "azurerm_management_lock" "this" {
  count      = var.enable_management_lock ? 1 : 0
  name       = "protect-${var.name}"
  scope      = azurerm_api_management.this.id
  lock_level = "CanNotDelete"
  notes      = "Protects API Management service from accidental deletion. Remove this lock before running terraform destroy."
}
