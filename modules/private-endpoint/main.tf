# Private DNS Zone — resolves the service's public hostname to a private IP
# inside the VNet, preventing traffic from leaving to the public internet.
resource "azurerm_private_dns_zone" "this" {
  name                = var.private_dns_zone_name
  resource_group_name = var.resource_group_name
  tags                = var.tags

  lifecycle {
    ignore_changes = [tags["CreatedDate"], tags["LastModified"]]
  }
}

# VNet link — attaches the DNS zone to the VNet so all resources inside
# the VNet resolve the private hostname without additional DNS configuration.
resource "azurerm_private_dns_zone_virtual_network_link" "this" {
  name                  = "link-${var.name}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.this.name
  virtual_network_id    = var.vnet_id
  registration_enabled  = false
  tags                  = var.tags

  lifecycle {
    ignore_changes = [tags["CreatedDate"], tags["LastModified"]]
  }
}

# Private Endpoint — places a NIC in snet-data with the service's private IP.
# After creation the service's public hostname (e.g. *.openai.azure.com)
# resolves to this private IP for all VNet clients.
resource "azurerm_private_endpoint" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  subnet_id           = var.subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-${var.name}"
    private_connection_resource_id = var.target_resource_id
    is_manual_connection           = false
    subresource_names              = var.subresource_names
  }

  private_dns_zone_group {
    name                 = "pdzg-${var.name}"
    private_dns_zone_ids = [azurerm_private_dns_zone.this.id]
  }

  lifecycle {
    ignore_changes = [tags["CreatedDate"], tags["LastModified"]]
  }

  depends_on = [azurerm_private_dns_zone_virtual_network_link.this]
}
