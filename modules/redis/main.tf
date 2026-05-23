# ==============================================================================
# Redis Cache
# ==============================================================================
resource "azurerm_redis_cache" "this" {
  count                = var.enable_redis ? 1 : 0
  name                 = var.name
  resource_group_name  = var.resource_group_name
  location             = var.location
  capacity             = var.capacity
  family               = var.family
  sku_name             = var.sku_name
  minimum_tls_version  = "1.2"
  non_ssl_port_enabled = false # hardcoded — plain-text Redis port must never be exposed
  tags                 = var.tags

  redis_configuration {
    maxmemory_policy = var.maxmemory_policy
  }

  lifecycle {
    ignore_changes = [tags["CreatedDate"], tags["LastModified"]]
  }
}
