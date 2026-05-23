# ==============================================================================
# Cosmos DB Account
# Cosmos DB enforces TLS 1.2+ at the service level natively.
# Local (key-based) authentication is disabled — Microsoft Entra ID only.
# ==============================================================================
resource "azurerm_cosmosdb_account" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  offer_type          = "Standard"
  kind                = var.kind

  # Disable key-based auth — enforce Microsoft Entra ID only
  local_authentication_disabled = true

  # Automatic failover promotes a secondary region if the write region goes down
  automatic_failover_enabled = var.enable_automatic_failover

  # Active-active multi-region writes — opt in via variable
  multiple_write_locations_enabled = var.enable_multi_write_locations

  # Restrict public network access when private endpoints are in use
  public_network_access_enabled = var.public_network_access_enabled

  # Azure Synapse Link analytical store
  analytical_storage_enabled = var.enable_analytical_storage

  consistency_policy {
    consistency_level       = var.consistency_level
    max_interval_in_seconds = var.max_interval_in_seconds
    max_staleness_prefix    = var.max_staleness_prefix
  }

  # Primary write region (failover_priority = 0)
  geo_location {
    location          = var.location
    failover_priority = 0
    zone_redundant    = var.zone_redundant
  }

  # Additional read / failover regions
  dynamic "geo_location" {
    for_each = var.failover_locations
    content {
      location          = geo_location.value.location
      failover_priority = geo_location.value.failover_priority
      zone_redundant    = coalesce(geo_location.value.zone_redundant, false)
    }
  }

  # Backup — Periodic uses interval/retention/redundancy; Continuous uses tier only
  backup {
    type                = var.backup_type
    tier                = var.backup_type == "Continuous" ? var.continuous_backup_tier : null
    interval_in_minutes = var.backup_type == "Periodic" ? var.backup_interval_in_minutes : null
    retention_in_hours  = var.backup_type == "Periodic" ? var.backup_retention_in_hours : null
    storage_redundancy  = var.backup_type == "Periodic" ? var.backup_storage_redundancy : null
  }

  # Free tier — one per subscription; use only in dev/test
  free_tier_enabled = var.enable_free_tier

  # Customer-Managed Key — Key Vault key URI for data-at-rest encryption
  key_vault_key_id = var.key_vault_key_id

  # VNet-based network filtering (use alongside or instead of private endpoints)
  is_virtual_network_filter_enabled = var.is_virtual_network_filter_enabled
  ip_range_filter                   = var.ip_range_filter

  # API capabilities — EnableMongo is injected automatically when kind = MongoDB
  dynamic "capabilities" {
    for_each = var.kind == "MongoDB" ? toset(concat(["EnableMongo"], var.additional_capabilities)) : toset(var.additional_capabilities)
    content {
      name = capabilities.value
    }
  }

  # VNet service endpoint rules
  dynamic "virtual_network_rule" {
    for_each = var.virtual_network_rules
    content {
      id                                   = virtual_network_rule.value.id
      ignore_missing_vnet_service_endpoint = virtual_network_rule.value.ignore_missing_vnet_service_endpoint
    }
  }

  # Managed identity — required for CMK and downstream RBAC role assignments
  dynamic "identity" {
    for_each = var.identity_type != null ? [1] : []
    content {
      type         = var.identity_type
      identity_ids = contains(["UserAssigned", "SystemAssigned, UserAssigned"], var.identity_type) ? var.user_assigned_identity_ids : null
    }
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [tags["CreatedDate"], tags["LastModified"]]
  }
}

# ==============================================================================
# SQL Databases
# ==============================================================================
resource "azurerm_cosmosdb_sql_database" "this" {
  for_each = var.databases

  name                = each.key
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.this.name

  # Autoscale throughput — mutually exclusive with manual throughput
  dynamic "autoscale_settings" {
    for_each = each.value.max_throughput != null ? [1] : []
    content {
      max_throughput = each.value.max_throughput
    }
  }

  # Manual throughput — only applied when autoscale is not configured
  throughput = each.value.max_throughput == null ? each.value.throughput : null
}

# ==============================================================================
# SQL Containers
# ==============================================================================
locals {
  # Flatten database → container entries into a single map keyed by "db/container"
  _containers = merge([
    for db_name, db in var.databases : {
      for ctr_name, ctr in coalesce(db.containers, {}) :
      "${db_name}/${ctr_name}" => merge(ctr, { database_name = db_name })
    }
  ]...)
}

resource "azurerm_cosmosdb_sql_container" "this" {
  for_each = local._containers

  name                  = split("/", each.key)[1]
  resource_group_name   = var.resource_group_name
  account_name          = azurerm_cosmosdb_account.this.name
  database_name         = each.value.database_name
  partition_key_paths   = [each.value.partition_key_path]
  partition_key_version = each.value.partition_key_version

  default_ttl            = each.value.default_ttl
  analytical_storage_ttl = each.value.analytical_storage_ttl

  dynamic "autoscale_settings" {
    for_each = each.value.max_throughput != null ? [1] : []
    content {
      max_throughput = each.value.max_throughput
    }
  }

  # Manual throughput — only applied when autoscale is not configured
  throughput = each.value.max_throughput == null ? each.value.throughput : null

  depends_on = [azurerm_cosmosdb_sql_database.this]
}

# ==============================================================================
# Management Lock (prod only)
# ==============================================================================
resource "azurerm_management_lock" "this" {
  count      = var.enable_management_lock ? 1 : 0
  name       = "protect-cosmosdb"
  scope      = azurerm_cosmosdb_account.this.id
  lock_level = "CanNotDelete"
  notes      = "Protects Cosmos DB account from accidental deletion. Remove this lock before running terraform destroy."
}

# ==============================================================================
# Metric Alerts
# ==============================================================================
resource "azurerm_monitor_metric_alert" "ru_consumption" {
  count               = var.enable_metric_alerts && var.action_group_id != null ? 1 : 0
  name                = "RU Consumption ${var.alert_ru_threshold}pct - ${var.name}"
  resource_group_name = var.resource_group_name
  scopes              = [azurerm_cosmosdb_account.this.id]
  description         = "Alert when normalized RU consumption exceeds ${var.alert_ru_threshold}%."
  frequency           = "PT5M"
  window_size         = "PT15M"
  severity            = 3
  auto_mitigate       = true
  tags                = var.tags

  criteria {
    metric_namespace = "Microsoft.DocumentDB/databaseAccounts"
    metric_name      = "NormalizedRUConsumption"
    aggregation      = "Maximum"
    operator         = "GreaterThan"
    threshold        = var.alert_ru_threshold
  }

  action { action_group_id = var.action_group_id }

  depends_on = [azurerm_cosmosdb_account.this]
  lifecycle { ignore_changes = [tags] }
}

resource "azurerm_monitor_metric_alert" "throttled_requests" {
  count               = var.enable_metric_alerts && var.action_group_id != null ? 1 : 0
  name                = "Throttled Requests - ${var.name}"
  resource_group_name = var.resource_group_name
  scopes              = [azurerm_cosmosdb_account.this.id]
  description         = "Alert when 429 throttled request count exceeds ${var.alert_throttled_requests_threshold}."
  frequency           = "PT5M"
  window_size         = "PT15M"
  severity            = 2
  auto_mitigate       = true
  tags                = var.tags

  criteria {
    metric_namespace = "Microsoft.DocumentDB/databaseAccounts"
    metric_name      = "TotalRequests"
    aggregation      = "Count"
    operator         = "GreaterThan"
    threshold        = var.alert_throttled_requests_threshold

    dimension {
      name     = "StatusCode"
      operator = "Include"
      values   = ["429"]
    }
  }

  action { action_group_id = var.action_group_id }

  depends_on = [azurerm_cosmosdb_account.this]
  lifecycle { ignore_changes = [tags] }
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
    private_connection_resource_id = azurerm_cosmosdb_account.this.id
    is_manual_connection           = false
    subresource_names              = [var.private_endpoint_subresource_name]
  }

  dynamic "private_dns_zone_group" {
    for_each = var.cosmos_db_dns_zone_id != null ? [1] : []
    content {
      name                 = "${var.name}-dns-zone-group"
      private_dns_zone_ids = [var.cosmos_db_dns_zone_id]
    }
  }

  lifecycle {
    ignore_changes = [tags["CreatedDate"], tags["LastModified"]]
  }
}

# ==============================================================================
# Diagnostic Settings
# ==============================================================================
resource "azurerm_monitor_diagnostic_setting" "this" {
  count                      = var.enable_diagnostic_settings && var.log_analytics_workspace_id != null ? 1 : 0
  name                       = "${var.name}-diagnostics"
  target_resource_id         = azurerm_cosmosdb_account.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log { category = "DataPlaneRequests" }
  enabled_log { category = "QueryRuntimeStatistics" }
  enabled_log { category = "PartitionKeyStatistics" }
  enabled_log { category = "PartitionKeyRUConsumption" }
  enabled_log { category = "ControlPlaneRequests" }
  enabled_metric { category = "Requests" }
}
