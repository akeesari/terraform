locals {
  subnets_map = { for s in var.subnets : s.name => s }
}

# ---------------------------------------------------------------------------
# Virtual Network
# ---------------------------------------------------------------------------
resource "azurerm_virtual_network" "this" {
  name                = var.vnet_name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.address_space
  dns_servers         = var.dns_servers
  tags                = var.tags

  lifecycle {
    ignore_changes = [tags["CreatedDate"], tags["LastModified"]]
  }
}

# ---------------------------------------------------------------------------
# Network Security Groups — one per subnet
# ---------------------------------------------------------------------------
resource "azurerm_network_security_group" "subnet" {
  for_each = local.subnets_map

  name                = coalesce(each.value.nsg_name, "nsg-${each.key}")
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  dynamic "security_rule" {
    for_each = each.value.nsg_security_rule != null ? each.value.nsg_security_rule : []
    content {
      name                       = security_rule.value.name
      priority                   = security_rule.value.priority
      direction                  = security_rule.value.direction
      access                     = security_rule.value.access
      protocol                   = security_rule.value.protocol
      source_port_range          = security_rule.value.source_port_range
      destination_port_range     = security_rule.value.destination_port_range
      destination_port_ranges    = security_rule.value.destination_port_ranges
      source_address_prefix      = security_rule.value.source_address_prefix
      destination_address_prefix = security_rule.value.destination_address_prefix
    }
  }
}

# ---------------------------------------------------------------------------
# Subnets
# ---------------------------------------------------------------------------
resource "azurerm_subnet" "this" {
  for_each = local.subnets_map

  name                 = each.key
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = each.value.address_prefixes
  service_endpoints    = each.value.service_endpoints

  private_endpoint_network_policies = coalesce(
    each.value.private_endpoint_network_policies,
    "Enabled"
  )

  dynamic "delegation" {
    for_each = each.value.delegation != null ? each.value.delegation : []
    content {
      name = delegation.value.name
      service_delegation {
        name    = delegation.value.service_delegation.name
        actions = delegation.value.service_delegation.actions
      }
    }
  }
}

# ---------------------------------------------------------------------------
# Route Tables — one per subnet that defines a route_table
# ---------------------------------------------------------------------------
resource "azurerm_route_table" "subnet" {
  for_each = { for k, s in local.subnets_map : k => s if s.route_table != null }

  name                          = each.value.route_table.name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  bgp_route_propagation_enabled = coalesce(each.value.bgp_route_propagation_enabled, false)
  tags                          = merge(var.tags, each.value.route_table.tags)

  dynamic "route" {
    for_each = each.value.route_table.routes
    content {
      name                   = route.value.name
      address_prefix         = route.value.address_prefix
      next_hop_type          = route.value.next_hop_type
      next_hop_in_ip_address = route.value.next_hop_in_ip_address
    }
  }
}

resource "azurerm_subnet_route_table_association" "subnet" {
  for_each = { for k, s in local.subnets_map : k => s if s.route_table != null }

  subnet_id      = azurerm_subnet.this[each.key].id
  route_table_id = azurerm_route_table.subnet[each.key].id
}

# ---------------------------------------------------------------------------
# NSG Associations
# ---------------------------------------------------------------------------
resource "azurerm_subnet_network_security_group_association" "subnet" {
  for_each = local.subnets_map

  subnet_id                 = azurerm_subnet.this[each.key].id
  network_security_group_id = azurerm_network_security_group.subnet[each.key].id
}
