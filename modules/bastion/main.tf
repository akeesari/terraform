# ==============================================================================
# Public IP for Bastion
# Bastion requires a Standard SKU, static public IP in the same VNet's resource group.
# ==============================================================================
resource "azurerm_public_ip" "this" {
  name                = "${var.name}-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"   # hardcoded — Bastion requires Static allocation
  sku                 = "Standard" # hardcoded — Bastion requires Standard SKU
  tags                = var.tags

  lifecycle {
    ignore_changes = [tags["CreatedDate"], tags["LastModified"]]
  }
}

# ==============================================================================
# Bastion Host
# The subnet must be named "AzureBastionSubnet" (Azure requirement).
# Copy tunneling and IP-based connection are available on Standard SKU only.
# ==============================================================================
resource "azurerm_bastion_host" "this" {
  name                   = var.name
  location               = var.location
  resource_group_name    = var.resource_group_name
  sku                    = var.sku
  scale_units            = var.scale_units
  copy_paste_enabled     = true # hardcoded — always allow clipboard use
  file_copy_enabled      = var.sku == "Standard" ? var.file_copy_enabled : false
  tunneling_enabled      = var.sku == "Standard" ? var.tunneling_enabled : false
  ip_connect_enabled     = var.sku == "Standard" ? var.ip_connect_enabled : false
  shareable_link_enabled = var.sku == "Standard" ? var.shareable_link_enabled : false
  tags                   = var.tags

  ip_configuration {
    name                 = "${var.name}-ipconfig"
    subnet_id            = var.subnet_id # must be an "AzureBastionSubnet" subnet
    public_ip_address_id = azurerm_public_ip.this.id
  }

  lifecycle {
    ignore_changes = [tags["CreatedDate"], tags["LastModified"]]
  }
}
