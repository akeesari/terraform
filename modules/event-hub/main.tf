# ==============================================================================
# Event Hub Namespace
# ==============================================================================
resource "azurerm_eventhub_namespace" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.sku
  capacity            = var.capacity

  # auto-inflate scales throughput units automatically under load (Standard only).
  auto_inflate_enabled     = var.sku == "Standard" ? var.auto_inflate_enabled : false
  maximum_throughput_units = var.sku == "Standard" && var.auto_inflate_enabled ? var.maximum_throughput_units : 0

  minimum_tls_version           = "1.2" # hardcoded security default
  local_authentication_enabled  = false # Entra-only auth; shared access keys disabled
  public_network_access_enabled = var.public_network_access_enabled
  tags                          = var.tags

  lifecycle {
    ignore_changes = [tags["CreatedDate"], tags["LastModified"]]
  }
}

# ==============================================================================
# Event Hubs
# ==============================================================================
resource "azurerm_eventhub" "this" {
  for_each = { for h in var.hubs : h.name => h }

  name              = each.key
  namespace_id      = azurerm_eventhub_namespace.this.id
  partition_count   = each.value.partition_count
  message_retention = each.value.message_retention
}

# ==============================================================================
# Consumer Groups
# The built-in '$Default' consumer group always exists and does not need to
# be declared here.  Add additional groups via var.consumer_groups.
# ==============================================================================
resource "azurerm_eventhub_consumer_group" "this" {
  # Key is "hub/group" to handle the same group name on different hubs.
  for_each = { for g in var.consumer_groups : "${g.eventhub_name}/${g.name}" => g }

  name                = each.value.name
  namespace_name      = azurerm_eventhub_namespace.this.name
  eventhub_name       = each.value.eventhub_name
  resource_group_name = var.resource_group_name
  user_metadata       = each.value.user_metadata
}

# ==============================================================================
# Management Lock
# ==============================================================================
resource "azurerm_management_lock" "this" {
  count      = var.enable_management_lock ? 1 : 0
  name       = "protect-${var.name}"
  scope      = azurerm_eventhub_namespace.this.id
  lock_level = "CanNotDelete"
  notes      = "Protects Event Hub namespace from accidental deletion. Remove this lock before running terraform destroy."
}
