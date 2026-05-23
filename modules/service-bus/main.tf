# ==============================================================================
# Service Bus Namespace
# ==============================================================================
resource "azurerm_servicebus_namespace" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.sku

  # For Premium SKU, capacity must be 1, 2, 4, 8, or 16.
  # For Basic and Standard, capacity must be 0.
  capacity = var.sku == "Premium" ? var.capacity : 0

  minimum_tls_version           = "1.2" # hardcoded security default
  local_auth_enabled            = false # Entra-only auth; shared access keys disabled
  public_network_access_enabled = var.public_network_access_enabled
  tags                          = var.tags

  lifecycle {
    ignore_changes = [tags["CreatedDate"], tags["LastModified"]]
  }
}

# ==============================================================================
# Queues
# ==============================================================================
resource "azurerm_servicebus_queue" "this" {
  for_each = { for q in var.queues : q.name => q }

  name         = each.key
  namespace_id = azurerm_servicebus_namespace.this.id

  # Practical defaults: dead-letter undeliverable messages and retry up to
  # max_delivery_count before moving them to the dead-letter sub-queue.
  max_delivery_count                   = each.value.max_delivery_count
  lock_duration                        = each.value.lock_duration
  dead_lettering_on_message_expiration = each.value.dead_lettering_on_message_expiration
  default_message_ttl                  = each.value.default_message_ttl
}

# ==============================================================================
# Topics  (Standard and Premium SKUs only; Basic does not support topics)
# ==============================================================================
resource "azurerm_servicebus_topic" "this" {
  for_each = var.sku != "Basic" ? toset(var.topics) : toset([])

  name         = each.key
  namespace_id = azurerm_servicebus_namespace.this.id
}

# ==============================================================================
# Management Lock
# ==============================================================================
resource "azurerm_management_lock" "this" {
  count      = var.enable_management_lock ? 1 : 0
  name       = "protect-${var.name}"
  scope      = azurerm_servicebus_namespace.this.id
  lock_level = "CanNotDelete"
  notes      = "Protects Service Bus namespace from accidental deletion. Remove this lock before running terraform destroy."
}
