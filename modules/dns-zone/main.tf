locals {
  is_public  = var.zone_type == "public"
  is_private = var.zone_type == "private"
  vnet_links = var.enable_dns_zone && local.is_private ? { for l in var.virtual_network_links : l.name => l } : {}
}

# ===========================================================================
# Public DNS Zone
# ===========================================================================

resource "azurerm_dns_zone" "this" {
  count               = var.enable_dns_zone && local.is_public ? 1 : 0
  name                = var.zone_name
  resource_group_name = var.resource_group_name
  tags                = var.tags

  lifecycle {
    ignore_changes = [tags["CreatedDate"], tags["LastModified"]]
  }
}

# NS delegation record in the parent zone (public zones only)
resource "azurerm_dns_ns_record" "delegation" {
  count               = var.enable_dns_zone && local.is_public && var.enable_parent_delegation ? 1 : 0
  name                = var.subdomain_prefix
  zone_name           = var.parent_zone_name
  resource_group_name = var.parent_zone_resource_group
  ttl                 = var.delegation_ttl
  records             = azurerm_dns_zone.this[0].name_servers
  tags                = var.tags

  lifecycle {
    ignore_changes = [tags["CreatedDate"], tags["LastModified"]]
  }
}

# ===========================================================================
# Private DNS Zone
# ===========================================================================

resource "azurerm_private_dns_zone" "this" {
  count               = var.enable_dns_zone && local.is_private ? 1 : 0
  name                = var.zone_name
  resource_group_name = var.resource_group_name
  tags                = var.tags

  dynamic "soa_record" {
    for_each = var.soa_record != null ? [var.soa_record] : []
    content {
      email        = soa_record.value.email
      expire_time  = soa_record.value.expire_time
      minimum_ttl  = soa_record.value.minimum_ttl
      refresh_time = soa_record.value.refresh_time
      retry_time   = soa_record.value.retry_time
      ttl          = soa_record.value.ttl
    }
  }

  lifecycle {
    ignore_changes = [tags["CreatedDate"], tags["LastModified"]]
  }
}

resource "azurerm_private_dns_zone_virtual_network_link" "this" {
  for_each              = local.vnet_links
  name                  = each.key
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.this[0].name
  virtual_network_id    = each.value.virtual_network_id
  registration_enabled  = each.value.registration_enabled
  tags                  = var.tags

  lifecycle {
    ignore_changes = [tags["CreatedDate"], tags["LastModified"]]
  }
}


