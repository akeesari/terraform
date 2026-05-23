resource "azurerm_postgresql_flexible_server" "this" {
  count                         = var.enable_postgres_server ? 1 : 0
  name                          = var.name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  administrator_login           = var.admin_login
  administrator_password        = var.admin_password
  sku_name                      = var.sku_name
  storage_mb                    = var.storage_mb
  version                       = var.server_version
  backup_retention_days         = var.backup_retention_days
  geo_redundant_backup_enabled  = var.geo_redundant_backup_enabled
  auto_grow_enabled             = var.auto_grow_enabled
  public_network_access_enabled = var.public_network_access_enabled
  delegated_subnet_id           = var.delegated_subnet_id
  private_dns_zone_id           = var.private_dns_zone_id
  zone                          = var.zone
  tags                          = var.tags

  # Managed identity for Azure Key Vault CMK integration
  dynamic "identity" {
    for_each = var.enable_cmk ? [1] : []
    content {
      type = "SystemAssigned"
    }
  }

  # Entra ID / password authentication modes
  dynamic "authentication" {
    for_each = var.enable_entra_auth ? [1] : []
    content {
      active_directory_auth_enabled = true
      password_auth_enabled         = var.enable_password_auth
    }
  }

  # High availability configuration
  dynamic "high_availability" {
    for_each = var.high_availability_mode != null ? [1] : []
    content {
      mode                      = var.high_availability_mode
      standby_availability_zone = var.standby_availability_zone
    }
  }

  # Maintenance window
  dynamic "maintenance_window" {
    for_each = var.maintenance_window != null ? [1] : []
    content {
      day_of_week  = var.maintenance_window.day_of_week
      start_hour   = var.maintenance_window.start_hour
      start_minute = var.maintenance_window.start_minute
    }
  }

  lifecycle {
    ignore_changes = [
      tags["CreatedDate"],
      tags["LastModified"],
      # Azure auto-assigns a zone when null is specified; ignore to prevent
      # immutable-field update errors on subsequent plans.
      zone
    ]
  }
}

resource "azurerm_postgresql_flexible_server_database" "databases" {
  for_each = {
    for db in var.databases : db.name => db
    if db.create && var.enable_postgres_server
  }

  name      = each.value.name
  server_id = azurerm_postgresql_flexible_server.this[0].id
  collation = var.db_collation
  charset   = var.db_charset
}

# =============================================================================
# Monitoring Alerts
# =============================================================================

# CPU Usage Alert
resource "azurerm_monitor_metric_alert" "cpu_usage" {
  count               = var.enable_postgres_server && var.enable_metric_alerts && var.action_group_id != null ? 1 : 0
  name                = "CPU Percent ${var.alert_cpu_threshold} percent - ${var.name}"
  resource_group_name = var.resource_group_name
  scopes              = [azurerm_postgresql_flexible_server.this[0].id]
  description         = "Action will be triggered when average CPU percentage is greater than ${var.alert_cpu_threshold}%."
  frequency           = "PT5M"
  window_size         = "PT15M"
  severity            = 3
  auto_mitigate       = true
  tags                = var.tags

  criteria {
    metric_namespace = "Microsoft.DBforPostgreSQL/flexibleServers"
    metric_name      = "cpu_percent"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = var.alert_cpu_threshold
  }

  action {
    action_group_id = var.action_group_id
  }

  depends_on = [azurerm_postgresql_flexible_server.this]

  lifecycle {
    ignore_changes = [tags]
  }
}

# Memory Usage Alert
resource "azurerm_monitor_metric_alert" "memory_usage" {
  count               = var.enable_postgres_server && var.enable_metric_alerts && var.action_group_id != null ? 1 : 0
  name                = "Memory Percent ${var.alert_memory_threshold} percent - ${var.name}"
  resource_group_name = var.resource_group_name
  scopes              = [azurerm_postgresql_flexible_server.this[0].id]
  description         = "Action will be triggered when average memory percentage is greater than ${var.alert_memory_threshold}%."
  frequency           = "PT5M"
  window_size         = "PT15M"
  severity            = 3
  auto_mitigate       = true
  tags                = var.tags

  criteria {
    metric_namespace = "Microsoft.DBforPostgreSQL/flexibleServers"
    metric_name      = "memory_percent"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = var.alert_memory_threshold
  }

  action {
    action_group_id = var.action_group_id
  }

  depends_on = [azurerm_postgresql_flexible_server.this]

  lifecycle {
    ignore_changes = [tags]
  }
}

# Storage Usage Alert
resource "azurerm_monitor_metric_alert" "storage_usage" {
  count               = var.enable_postgres_server && var.enable_metric_alerts && var.action_group_id != null ? 1 : 0
  name                = "Storage Percent ${var.alert_storage_threshold} percent - ${var.name}"
  resource_group_name = var.resource_group_name
  scopes              = [azurerm_postgresql_flexible_server.this[0].id]
  description         = "Action will be triggered when storage percentage is greater than ${var.alert_storage_threshold}%."
  frequency           = "PT5M"
  window_size         = "PT15M"
  severity            = 2 # Higher severity for storage
  auto_mitigate       = true
  tags                = var.tags

  criteria {
    metric_namespace = "Microsoft.DBforPostgreSQL/flexibleServers"
    metric_name      = "storage_percent"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = var.alert_storage_threshold
  }

  action {
    action_group_id = var.action_group_id
  }

  depends_on = [azurerm_postgresql_flexible_server.this]

  lifecycle {
    ignore_changes = [tags]
  }
}

# Connection Failures Alert
resource "azurerm_monitor_metric_alert" "connection_failures" {
  count               = var.enable_postgres_server && var.enable_metric_alerts && var.action_group_id != null ? 1 : 0
  name                = "Connection Failures - ${var.name}"
  resource_group_name = var.resource_group_name
  scopes              = [azurerm_postgresql_flexible_server.this[0].id]
  description         = "Action will be triggered when connection failures exceed ${var.alert_connection_failures_threshold}."
  frequency           = "PT5M"
  window_size         = "PT15M"
  severity            = 2
  auto_mitigate       = true
  tags                = var.tags

  criteria {
    metric_namespace = "Microsoft.DBforPostgreSQL/flexibleServers"
    metric_name      = "connections_failed"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = var.alert_connection_failures_threshold
  }

  action {
    action_group_id = var.action_group_id
  }

  depends_on = [azurerm_postgresql_flexible_server.this]

  lifecycle {
    ignore_changes = [tags]
  }
}
