# ==============================================================================
# Public IP Prefix
# A prefix provides a contiguous block of public IPs that can be allow-listed
# in downstream firewalls (e.g. AKS egress, App Service outbound).
# ==============================================================================
resource "azurerm_public_ip_prefix" "this" {
  count               = var.enable_nat_gateway ? 1 : 0
  name                = "${var.name}-pip-prefix"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard" # hardcoded — Basic SKU is not compatible with NAT Gateway
  ip_version          = "IPv4"
  prefix_length       = var.prefix_length
  tags                = var.tags

  lifecycle {
    ignore_changes = [tags["CreatedDate"], tags["LastModified"]]
  }
}

# ==============================================================================
# NAT Gateway
# ==============================================================================
resource "azurerm_nat_gateway" "this" {
  count                   = var.enable_nat_gateway ? 1 : 0
  name                    = var.name
  location                = var.location
  resource_group_name     = var.resource_group_name
  sku_name                = "Standard" # hardcoded — only SKU available
  idle_timeout_in_minutes = var.idle_timeout_in_minutes
  zones                   = var.zones
  tags                    = var.tags

  lifecycle {
    ignore_changes = [tags["CreatedDate"], tags["LastModified"]]
  }
}

# ==============================================================================
# Associate Public IP Prefix → NAT Gateway
# ==============================================================================
resource "azurerm_nat_gateway_public_ip_prefix_association" "this" {
  count               = var.enable_nat_gateway ? 1 : 0
  nat_gateway_id      = azurerm_nat_gateway.this[0].id
  public_ip_prefix_id = azurerm_public_ip_prefix.this[0].id
}

# ==============================================================================
# Subnet Associations
# Each entry in var.subnet_ids is associated with the NAT gateway so that all
# outbound traffic from those subnets uses the deterministic IP prefix.
# ==============================================================================
resource "azurerm_subnet_nat_gateway_association" "this" {
  for_each = var.enable_nat_gateway ? toset(var.subnet_ids) : toset([])

  subnet_id      = each.value
  nat_gateway_id = azurerm_nat_gateway.this[0].id
}
