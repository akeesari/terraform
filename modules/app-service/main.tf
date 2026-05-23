locals {
  base_app_settings = {
    APPINSIGHTS_INSTRUMENTATIONKEY        = try(azurerm_application_insights.this[0].instrumentation_key, "")
    APPLICATIONINSIGHTS_CONNECTION_STRING = try(azurerm_application_insights.this[0].connection_string, "")
    ENVIRONMENT                           = var.environment
  }
  merged_app_settings = merge(local.base_app_settings, var.common_app_settings)
}

resource "azurerm_service_plan" "this" {
  count               = var.enable_plan ? 1 : 0
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = "Linux"
  sku_name            = var.sku_name
  tags                = var.tags

  lifecycle {
    ignore_changes = [tags["CreatedDate"], tags["LastModified"]]
  }
}

resource "azurerm_application_insights" "this" {
  count               = var.enable_app_insights ? 1 : 0
  name                = var.app_insights_name
  location            = var.location
  resource_group_name = var.resource_group_name
  application_type    = "web"
  workspace_id        = var.log_analytics_workspace_id
  tags                = var.tags

  lifecycle {
    ignore_changes = [tags["CreatedDate"], tags["LastModified"]]
  }
}

resource "azurerm_linux_web_app" "app" {
  count                   = var.enable_web_app && var.enable_plan ? 1 : 0
  name                    = var.web_app_name
  location                = var.location
  resource_group_name     = var.resource_group_name
  service_plan_id         = azurerm_service_plan.this[0].id
  https_only              = true
  client_affinity_enabled = var.client_affinity_enabled
  tags                    = var.tags

  site_config {
    always_on           = true
    minimum_tls_version = "1.2"
  }

  app_settings = local.merged_app_settings

  depends_on = [azurerm_service_plan.this, azurerm_application_insights.this]

  lifecycle {
    ignore_changes = [tags["CreatedDate"], tags["LastModified"]]
  }
}

resource "azurerm_linux_web_app" "api" {
  count                   = var.enable_api_app && var.enable_plan ? 1 : 0
  name                    = var.api_app_name
  location                = var.location
  resource_group_name     = var.resource_group_name
  service_plan_id         = azurerm_service_plan.this[0].id
  https_only              = true
  client_affinity_enabled = var.client_affinity_enabled
  tags                    = var.tags

  site_config {
    always_on           = true
    minimum_tls_version = "1.2"
  }

  app_settings = local.merged_app_settings

  depends_on = [azurerm_service_plan.this, azurerm_application_insights.this]

  lifecycle {
    ignore_changes = [tags["CreatedDate"], tags["LastModified"]]
  }
}
