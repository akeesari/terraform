locals {
  # Compute non-overlapping subnet CIDRs from the VNet address prefix.
  # Assumes the VNet is at least /16. Layout for a 10.x.0.0/16:
  #   snet-aks    /20  (netnum 0)  -> 10.x.0.0/20   (4,091 IPs — AKS nodes & pods)
  #   snet-app    /22  (netnum 4)  -> 10.x.16.0/22  (1,019 IPs — App Service / Container Apps)
  #   snet-data   /22  (netnum 5)  -> 10.x.20.0/22  (1,019 IPs — Private Endpoints / databases)
  #   snet-shared /24  (netnum 24) -> 10.x.24.0/24  (251 IPs  — CI/CD agents, jump boxes)
  subnets = {
    aks = {
      name           = "snet-aks"
      address_prefix = cidrsubnet(var.vnet_address_prefix, 4, 0)
    }
    app = {
      name           = "snet-app"
      address_prefix = cidrsubnet(var.vnet_address_prefix, 6, 4)
    }
    data = {
      name           = "snet-data"
      address_prefix = cidrsubnet(var.vnet_address_prefix, 6, 5)
    }
    shared = {
      name           = "snet-shared"
      address_prefix = cidrsubnet(var.vnet_address_prefix, 8, 24)
    }
  }
}

# ==============================================================================
# Network Security Groups
# ==============================================================================

# AKS NSG — allows Azure Load Balancer and intra-VNet, denies everything else.
resource "azurerm_network_security_group" "aks" {
  name                = "nsg-snet-aks"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  security_rule {
    name                       = "AllowAzureLoadBalancerInbound"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_address_prefix      = "AzureLoadBalancer"
    source_port_range          = "*"
    destination_address_prefix = "*"
    destination_port_range     = "*"
  }

  security_rule {
    name                       = "AllowVNetInbound"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_address_prefix      = "VirtualNetwork"
    source_port_range          = "*"
    destination_address_prefix = "VirtualNetwork"
    destination_port_range     = "*"
  }

  security_rule {
    name                       = "DenyAllInbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_address_prefix      = "*"
    source_port_range          = "*"
    destination_address_prefix = "*"
    destination_port_range     = "*"
  }

  lifecycle {
    ignore_changes = [tags["CreatedDate"], tags["LastModified"]]
  }
}

# App NSG — deny-all inbound; app traffic is load-balanced from the AKS subnet.
resource "azurerm_network_security_group" "app" {
  name                = "nsg-snet-app"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  security_rule {
    name                       = "DenyAllInbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_address_prefix      = "*"
    source_port_range          = "*"
    destination_address_prefix = "*"
    destination_port_range     = "*"
  }

  lifecycle {
    ignore_changes = [tags["CreatedDate"], tags["LastModified"]]
  }
}

# Data NSG — only the AKS and App subnets may reach DB/cache/private-endpoint ports.
resource "azurerm_network_security_group" "data" {
  name                = "nsg-snet-data"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  security_rule {
    name                       = "AllowFromAksSubnet"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefix      = local.subnets.aks.address_prefix
    source_port_range          = "*"
    destination_address_prefix = "*"
    destination_port_ranges    = ["1433", "5432", "6380", "443"]
  }

  security_rule {
    name                       = "AllowFromAppSubnet"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefix      = local.subnets.app.address_prefix
    source_port_range          = "*"
    destination_address_prefix = "*"
    destination_port_ranges    = ["1433", "5432", "6380", "443"]
  }

  security_rule {
    name                       = "DenyAllInbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_address_prefix      = "*"
    source_port_range          = "*"
    destination_address_prefix = "*"
    destination_port_range     = "*"
  }

  lifecycle {
    ignore_changes = [tags["CreatedDate"], tags["LastModified"]]
  }
}

# Shared NSG — deny-all inbound; individual rules added per CI/CD agent or jump box need.
resource "azurerm_network_security_group" "shared" {
  name                = "nsg-snet-shared"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  security_rule {
    name                       = "DenyAllInbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_address_prefix      = "*"
    source_port_range          = "*"
    destination_address_prefix = "*"
    destination_port_range     = "*"
  }

  lifecycle {
    ignore_changes = [tags["CreatedDate"], tags["LastModified"]]
  }
}

# ==============================================================================
# Virtual Network + Subnets
# ==============================================================================

resource "azurerm_virtual_network" "this" {
  name                = var.vnet_name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = [var.vnet_address_prefix]
  tags                = var.tags

  dynamic "ddos_protection_plan" {
    for_each = var.enable_ddos_protection && var.ddos_protection_plan_id != null ? [1] : []
    content {
      id     = var.ddos_protection_plan_id
      enable = true
    }
  }
}

resource "azurerm_subnet" "aks" {
  name                 = local.subnets.aks.name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [local.subnets.aks.address_prefix]
}

resource "azurerm_subnet_network_security_group_association" "aks" {
  subnet_id                 = azurerm_subnet.aks.id
  network_security_group_id = azurerm_network_security_group.aks.id
}

resource "azurerm_subnet" "app" {
  name                 = local.subnets.app.name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [local.subnets.app.address_prefix]

  delegation {
    name = "delegation-web"
    service_delegation {
      name = var.app_subnet_delegation
    }
  }

  # Azure auto-injects `actions` into service delegations after creation.
  # Ignoring delegation prevents a perpetual diff in terraform plan.
  lifecycle {
    ignore_changes = [delegation]
  }
}

resource "azurerm_subnet_network_security_group_association" "app" {
  subnet_id                 = azurerm_subnet.app.id
  network_security_group_id = azurerm_network_security_group.app.id
}

resource "azurerm_subnet" "data" {
  name                 = local.subnets.data.name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [local.subnets.data.address_prefix]
}

resource "azurerm_subnet_network_security_group_association" "data" {
  subnet_id                 = azurerm_subnet.data.id
  network_security_group_id = azurerm_network_security_group.data.id
}

resource "azurerm_subnet" "shared" {
  name                 = local.subnets.shared.name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [local.subnets.shared.address_prefix]
}

resource "azurerm_subnet_network_security_group_association" "shared" {
  subnet_id                 = azurerm_subnet.shared.id
  network_security_group_id = azurerm_network_security_group.shared.id
}
