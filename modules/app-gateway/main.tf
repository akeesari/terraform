locals {
  frontend_ip_config_name  = "${var.name}-feip"
  frontend_port_http_name  = "port-80"
  frontend_port_https_name = "port-443"
}

# ==============================================================================
# Public IP
# Application Gateway v2 requires a Standard SKU, static public IP.
# zones controls availability zone placement; omit for regional (non-zonal).
# ==============================================================================
resource "azurerm_public_ip" "this" {
  name                = "${var.name}-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"   # hardcoded — AppGw v2 requires Static allocation
  sku                 = "Standard" # hardcoded — AppGw v2 requires Standard SKU
  zones               = var.zones
  tags                = var.tags

  lifecycle {
    ignore_changes = [tags["CreatedDate"], tags["LastModified"]]
  }
}

# ==============================================================================
# NSG for the Application Gateway subnet
# Azure REQUIRES the GatewayManager rule (65200–65535) for infrastructure health
# probes. The AzureFrontDoor.Backend rule (443) is needed when the gateway sits
# behind Front Door Premium with Private Link. Both are always added when
# enable_nsg = true; additional_nsg_rules lets callers append custom rules.
# ==============================================================================
resource "azurerm_network_security_group" "this" {
  count               = var.enable_nsg ? 1 : 0
  name                = "${var.name}-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  security_rule {
    name                       = "Allow-GatewayManager-Inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["65200-65535"]
    source_address_prefix      = "GatewayManager"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-AzureFrontDoor-Backend-HTTPS-Inbound"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "AzureFrontDoor.Backend"
    destination_address_prefix = "*"
  }

  dynamic "security_rule" {
    for_each = var.additional_nsg_rules
    content {
      name              = security_rule.value.name
      priority          = security_rule.value.priority
      direction         = security_rule.value.direction
      access            = security_rule.value.access
      protocol          = security_rule.value.protocol
      source_port_range = "*"
      # Exactly one of destination_port_range (string) or destination_port_ranges (list) may be
      # set per rule — the provider rejects both being non-null simultaneously.
      destination_port_range     = length(coalesce(security_rule.value.destination_port_ranges, [])) == 0 ? security_rule.value.destination_port_range : null
      destination_port_ranges    = length(coalesce(security_rule.value.destination_port_ranges, [])) > 0 ? security_rule.value.destination_port_ranges : null
      source_address_prefix      = security_rule.value.source_address_prefix
      destination_address_prefix = security_rule.value.destination_address_prefix
    }
  }

  lifecycle {
    ignore_changes = [tags["CreatedDate"], tags["LastModified"]]
  }
}

resource "azurerm_subnet_network_security_group_association" "this" {
  count                     = var.enable_nsg ? 1 : 0
  subnet_id                 = var.subnet_id
  network_security_group_id = azurerm_network_security_group.this[0].id
}

# ==============================================================================
# Application Gateway v2
# SKU defaults to WAF_v2 (Prevention mode, OWASP 3.2).
# TLS 1.2 minimum is hardcoded via the AppGwSslPolicy20220101 predefined policy.
# ==============================================================================
resource "azurerm_application_gateway" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  enable_http2        = var.enable_http2
  firewall_policy_id  = var.waf_policy_id
  tags                = var.tags

  # --------------------------------------------------------------------------
  # SKU + autoscaling
  # capacity is omitted from sku when autoscale_configuration is present.
  # --------------------------------------------------------------------------
  sku {
    name = var.sku_name
    tier = var.sku_name
  }

  autoscale_configuration {
    min_capacity = var.min_capacity
    max_capacity = var.max_capacity
  }

  # --------------------------------------------------------------------------
  # Network plumbing
  # subnet_id must be a dedicated AppGateway subnet (no other resources).
  # --------------------------------------------------------------------------
  gateway_ip_configuration {
    name      = "${var.name}-ipconfig"
    subnet_id = var.subnet_id
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_config_name
    public_ip_address_id = azurerm_public_ip.this.id
  }

  dynamic "frontend_ip_configuration" {
    for_each = var.private_ip_address != null ? [1] : []
    content {
      name                          = "${var.name}-feip-private"
      subnet_id                     = var.subnet_id
      private_ip_address            = var.private_ip_address
      private_ip_address_allocation = "Static"
    }
  }

  frontend_port {
    name = local.frontend_port_http_name
    port = 80
  }

  dynamic "frontend_port" {
    for_each = var.enable_https ? [1] : []
    content {
      name = local.frontend_port_https_name
      port = 443
    }
  }

  # --------------------------------------------------------------------------
  # Managed identity — required when referencing SSL certs stored in Key Vault.
  # --------------------------------------------------------------------------
  dynamic "identity" {
    for_each = var.enable_identity ? [1] : []
    content {
      type         = "UserAssigned"
      identity_ids = var.identity_ids
    }
  }

  # --------------------------------------------------------------------------
  # TLS policy — hardcoded to TLS 1.2 minimum, applied when HTTPS is enabled.
  # AppGwSslPolicy20220101 enforces TLS 1.2+ with strong cipher suites.
  # --------------------------------------------------------------------------
  dynamic "ssl_policy" {
    for_each = var.enable_https ? [1] : []
    content {
      policy_type = "Predefined"
      policy_name = "AppGwSslPolicy20220101" # TLS 1.2 minimum — hardcoded, never expose as variable
    }
  }

  # --------------------------------------------------------------------------
  # SSL certificates — sensitive, support PFX (data+password) or Key Vault refs.
  # --------------------------------------------------------------------------
  dynamic "ssl_certificate" {
    for_each = var.ssl_certificates
    content {
      name                = ssl_certificate.key
      data                = ssl_certificate.value.data
      password            = ssl_certificate.value.password
      key_vault_secret_id = ssl_certificate.value.key_vault_secret_id
    }
  }

  # --------------------------------------------------------------------------
  # Trusted root certificates — for end-to-end TLS when backends present
  # self-signed or internal CA certificates. Supply DER-encoded data or a
  # Key Vault secret ID containing the root cert.
  # --------------------------------------------------------------------------
  dynamic "trusted_root_certificate" {
    for_each = var.trusted_root_certificates
    content {
      name                = trusted_root_certificate.key
      data                = trusted_root_certificate.value.data
      key_vault_secret_id = trusted_root_certificate.value.key_vault_secret_id
    }
  }

  # --------------------------------------------------------------------------
  # Backend address pools
  # --------------------------------------------------------------------------
  dynamic "backend_address_pool" {
    for_each = var.backend_pools
    content {
      name         = backend_address_pool.key
      fqdns        = backend_address_pool.value.fqdns
      ip_addresses = backend_address_pool.value.ip_addresses
    }
  }

  # --------------------------------------------------------------------------
  # Backend HTTP settings
  # --------------------------------------------------------------------------
  dynamic "backend_http_settings" {
    for_each = var.backend_http_settings
    content {
      name                                = backend_http_settings.key
      cookie_based_affinity               = backend_http_settings.value.cookie_based_affinity
      port                                = backend_http_settings.value.port
      protocol                            = backend_http_settings.value.protocol
      request_timeout                     = backend_http_settings.value.request_timeout
      probe_name                          = backend_http_settings.value.probe_name
      host_name                           = backend_http_settings.value.host_name
      pick_host_name_from_backend_address = backend_http_settings.value.pick_host_name_from_backend_address
      trusted_root_certificate_names      = backend_http_settings.value.trusted_root_certificate_names
    }
  }

  # --------------------------------------------------------------------------
  # Health probes — optional match block lets you accept custom status codes
  # or validate a specific response body (e.g. treat 200 and 404 as healthy).
  # --------------------------------------------------------------------------
  dynamic "probe" {
    for_each = var.health_probes
    content {
      name                                      = probe.key
      protocol                                  = probe.value.protocol
      host                                      = probe.value.host
      path                                      = probe.value.path
      interval                                  = probe.value.interval
      timeout                                   = probe.value.timeout
      unhealthy_threshold                       = probe.value.unhealthy_threshold
      pick_host_name_from_backend_http_settings = probe.value.pick_host_name_from_backend_http_settings

      dynamic "match" {
        for_each = probe.value.match != null ? [probe.value.match] : []
        content {
          body        = match.value.body
          status_code = match.value.status_codes
        }
      }
    }
  }

  # --------------------------------------------------------------------------
  # HTTP listeners — host_names (list) supports multi-site SNI listeners.
  # Use host_name for a single hostname or host_names for multiple SANs.
  # --------------------------------------------------------------------------
  dynamic "http_listener" {
    for_each = var.http_listeners
    content {
      name                           = http_listener.key
      frontend_ip_configuration_name = local.frontend_ip_config_name
      frontend_port_name             = http_listener.value.protocol == "Https" ? local.frontend_port_https_name : local.frontend_port_http_name
      protocol                       = http_listener.value.protocol
      host_name                      = http_listener.value.host_name
      host_names                     = http_listener.value.host_names
      require_sni                    = http_listener.value.require_sni
      ssl_certificate_name           = http_listener.value.protocol == "Https" ? http_listener.value.ssl_certificate_name : null
    }
  }

  # --------------------------------------------------------------------------
  # URL path maps — enable path-based routing (rule_type = PathBasedRouting).
  # --------------------------------------------------------------------------
  dynamic "url_path_map" {
    for_each = var.url_path_maps
    content {
      name                               = url_path_map.key
      default_backend_address_pool_name  = url_path_map.value.default_backend_address_pool_name
      default_backend_http_settings_name = url_path_map.value.default_backend_http_settings_name

      dynamic "path_rule" {
        for_each = url_path_map.value.path_rules
        content {
          name                       = path_rule.value.name
          paths                      = path_rule.value.paths
          backend_address_pool_name  = path_rule.value.backend_address_pool_name
          backend_http_settings_name = path_rule.value.backend_http_settings_name
        }
      }
    }
  }

  # --------------------------------------------------------------------------
  # Request routing rules
  # rule_type: Basic (single backend) or PathBasedRouting (requires url_path_map_name).
  # priority is required for Application Gateway v2 and must be unique across rules.
  # --------------------------------------------------------------------------
  dynamic "request_routing_rule" {
    for_each = var.request_routing_rules
    content {
      name                        = request_routing_rule.key
      rule_type                   = request_routing_rule.value.rule_type
      http_listener_name          = request_routing_rule.value.listener_name
      backend_address_pool_name   = request_routing_rule.value.backend_address_pool_name
      backend_http_settings_name  = request_routing_rule.value.backend_http_settings_name
      redirect_configuration_name = request_routing_rule.value.redirect_configuration_name
      url_path_map_name           = request_routing_rule.value.url_path_map_name
      priority                    = request_routing_rule.value.priority
    }
  }

  # --------------------------------------------------------------------------
  # Redirect configurations.
  # redirect_type defaults to Permanent (301) for HTTP→HTTPS but can be
  # overridden when you need Found (302) / SeeOther / Temporary.
  # target_url is an alternative to target_listener_name for external redirects.
  # --------------------------------------------------------------------------
  dynamic "redirect_configuration" {
    for_each = var.redirect_configurations
    content {
      name                 = redirect_configuration.key
      redirect_type        = redirect_configuration.value.redirect_type
      target_listener_name = redirect_configuration.value.target_listener_name
      target_url           = redirect_configuration.value.target_url
      include_path         = redirect_configuration.value.include_path
      include_query_string = redirect_configuration.value.include_query_string
    }
  }

  # --------------------------------------------------------------------------
  # WAF configuration — Prevention mode, OWASP 3.2, hardcoded.
  # Only used when sku_name = WAF_v2 and no standalone waf_policy_id is set.
  # When waf_policy_id is provided the standalone policy takes precedence.
  # --------------------------------------------------------------------------
  dynamic "waf_configuration" {
    for_each = var.sku_name == "WAF_v2" && var.enable_waf && var.waf_policy_id == null ? [1] : []
    content {
      enabled                  = true
      firewall_mode            = "Prevention" # hardcoded — never Detection in production
      rule_set_type            = "OWASP"
      rule_set_version         = "3.2"
      request_body_check       = true
      max_request_body_size_kb = var.waf_max_request_body_size_kb
      file_upload_limit_mb     = var.waf_file_upload_limit_mb
    }
  }

  lifecycle {
    ignore_changes = [tags["CreatedDate"], tags["LastModified"]]
  }
}

# ==============================================================================
# Diagnostic Settings
# Sends AppGw access, performance, and firewall (WAF) logs to Log Analytics.
# ==============================================================================
resource "azurerm_monitor_diagnostic_setting" "this" {
  count              = var.enable_diagnostics ? 1 : 0
  name               = "diag-${var.name}"
  target_resource_id = azurerm_application_gateway.this.id

  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log { category = "ApplicationGatewayAccessLog" }
  enabled_log { category = "ApplicationGatewayPerformanceLog" }
  enabled_log { category = "ApplicationGatewayFirewallLog" }

  metric {
    category = "AllMetrics"
    enabled  = true
  }

  lifecycle {
    ignore_changes = [log_analytics_destination_type]
  }
}

# ==============================================================================
# Management Lock
# ==============================================================================
resource "azurerm_management_lock" "this" {
  count      = var.enable_management_lock ? 1 : 0
  name       = "${var.name}-lock"
  scope      = azurerm_application_gateway.this.id
  lock_level = "CanNotDelete"
  notes      = "Protected by Terraform"
}
