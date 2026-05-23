# ==============================================================================
# Front Door Profile
# ==============================================================================
resource "azurerm_cdn_frontdoor_profile" "this" {
  name                     = var.name
  resource_group_name      = var.resource_group_name
  sku_name                 = var.sku_name
  response_timeout_seconds = var.response_timeout_seconds
  tags                     = var.tags

  lifecycle {
    ignore_changes = [tags["CreatedDate"], tags["LastModified"]]
  }
}

# ==============================================================================
# Endpoint
# ==============================================================================
resource "azurerm_cdn_frontdoor_endpoint" "this" {
  name                     = "${var.name}-endpoint"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id
  tags                     = var.tags

  lifecycle {
    ignore_changes = [tags["CreatedDate"], tags["LastModified"]]
  }
}

# ==============================================================================
# Origin Group
# ==============================================================================
resource "azurerm_cdn_frontdoor_origin_group" "this" {
  name                                                      = "${var.name}-origin-group"
  cdn_frontdoor_profile_id                                  = azurerm_cdn_frontdoor_profile.this.id
  restore_traffic_time_to_healed_or_new_endpoint_in_minutes = var.restore_traffic_time_to_healed_in_minutes
  session_affinity_enabled                                  = var.session_affinity_enabled

  load_balancing {
    sample_size                        = 4
    successful_samples_required        = 3
    additional_latency_in_milliseconds = var.additional_latency_in_milliseconds
  }

  health_probe {
    interval_in_seconds = var.health_probe_interval_in_seconds
    path                = var.health_probe_path
    protocol            = "Https" # hardcoded — never probe over plain HTTP
    request_type        = "HEAD"
  }
}

# ==============================================================================
# Origins
# ==============================================================================
resource "azurerm_cdn_frontdoor_origin" "this" {
  for_each = var.origins

  name                           = each.key
  cdn_frontdoor_origin_group_id  = azurerm_cdn_frontdoor_origin_group.this.id
  host_name                      = each.value.host_name
  http_port                      = coalesce(each.value.http_port, 80)
  https_port                     = coalesce(each.value.https_port, 443)
  origin_host_header             = coalesce(each.value.host_header, each.value.host_name)
  priority                       = coalesce(each.value.priority, 1)
  weight                         = coalesce(each.value.weight, 500)
  enabled                        = true
  certificate_name_check_enabled = true # security default — always validate TLS cert on origin
}

# ==============================================================================
# Route
# ==============================================================================
resource "azurerm_cdn_frontdoor_route" "this" {
  name                          = "${var.name}-route"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.this.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.this.id
  cdn_frontdoor_origin_ids      = [for o in azurerm_cdn_frontdoor_origin.this : o.id]
  https_redirect_enabled        = true        # hardcoded — always redirect HTTP → HTTPS
  forwarding_protocol           = "HttpsOnly" # hardcoded — never forward plain HTTP to origin
  link_to_default_domain        = true
  patterns_to_match             = var.patterns_to_match
  supported_protocols           = ["Http", "Https"]
}

# ==============================================================================
# WAF Policy
# Managed rule sets (Microsoft_DefaultRuleSet, BotManagerRuleSet) require
# Premium_AzureFrontDoor. Standard SKU supports custom rules only.
# ==============================================================================
resource "azurerm_cdn_frontdoor_firewall_policy" "this" {
  count               = var.enable_waf ? 1 : 0
  name                = replace("${var.name}waf", "-", "")
  resource_group_name = var.resource_group_name
  sku_name            = var.sku_name
  enabled             = true
  mode                = var.waf_mode
  tags                = var.tags

  dynamic "managed_rule" {
    for_each = var.sku_name == "Premium_AzureFrontDoor" ? [1] : []
    content {
      type    = "Microsoft_DefaultRuleSet"
      version = "2.1"
      action  = "Block"
    }
  }

  dynamic "managed_rule" {
    for_each = var.sku_name == "Premium_AzureFrontDoor" ? [1] : []
    content {
      type    = "Microsoft_BotManagerRuleSet"
      version = "1.0"
      action  = "Block"
    }
  }

  lifecycle {
    ignore_changes = [tags["CreatedDate"], tags["LastModified"]]
  }
}

resource "azurerm_cdn_frontdoor_security_policy" "this" {
  count                    = var.enable_waf ? 1 : 0
  name                     = "${var.name}-security-policy"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id

  security_policies {
    firewall {
      cdn_frontdoor_firewall_policy_id = azurerm_cdn_frontdoor_firewall_policy.this[0].id

      association {
        domain {
          cdn_frontdoor_domain_id = azurerm_cdn_frontdoor_endpoint.this.id
        }
        patterns_to_match = ["/*"]
      }
    }
  }
}
