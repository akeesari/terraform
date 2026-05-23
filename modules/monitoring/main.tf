resource "azurerm_log_analytics_workspace" "this" {
  count               = var.enable_log_analytics ? 1 : 0
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.sku
  retention_in_days   = var.retention_in_days
  daily_quota_gb      = var.daily_quota_gb
  tags                = var.tags

  # When true, disables shared-key auth and requires Entra identities for all
  # data ingestion and query access. Maps to the Defender for Cloud
  # "Log Analytics workspaces should block non-Azure AD-based ingestion" recommendation.
  local_authentication_enabled = false

  lifecycle {
    ignore_changes = [tags["CreatedDate"], tags["LastModified"]]
  }
}

resource "azurerm_application_insights" "this" {
  count               = var.enable_application_insights ? 1 : 0
  name                = coalesce(var.app_insights_name, "${var.name}-appins")
  resource_group_name = var.resource_group_name
  location            = var.location
  application_type    = "web"
  workspace_id        = try(azurerm_log_analytics_workspace.this[0].id, null)
  tags                = var.tags

  lifecycle {
    ignore_changes = [tags["CreatedDate"], tags["LastModified"]]
  }
}

resource "azurerm_monitor_action_group" "this" {
  count               = var.enable_alerts ? 1 : 0
  name                = coalesce(var.action_group_name, "${var.name}-ag")
  resource_group_name = var.resource_group_name
  short_name          = var.action_group_short_name
  tags                = var.tags

  dynamic "email_receiver" {
    for_each = var.alert_email_addresses
    content {
      name                    = "email-${email_receiver.key}"
      email_address           = email_receiver.value
      use_common_alert_schema = true
    }
  }

  lifecycle {
    ignore_changes = [tags["CreatedDate"], tags["LastModified"]]
  }
}
