variable "name" {
  type        = string
  description = "Application Gateway name (1–80 chars, alphanumeric, hyphens, underscores, and periods)."

  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9._-]{0,78}[a-zA-Z0-9_]$", var.name))
    error_message = "name must be 1–80 chars, start with alphanumeric, and contain only alphanumeric, hyphens, underscores, and periods."
  }
}

variable "resource_group_name" {
  type        = string
  description = "Resource group to place the Application Gateway in."
}

variable "location" {
  type        = string
  description = "Azure region for the Application Gateway and its public IP."
}

variable "subnet_id" {
  type        = string
  description = "Resource ID of the dedicated Application Gateway subnet. No other resources may share this subnet."
}

variable "zones" {
  type        = list(string)
  description = "Availability zones for the public IP. Example: [\"1\", \"2\", \"3\"] for zone-redundant. Null = regional (non-zonal)."
  default     = null
}

# ==============================================================================
# SKU + capacity
# ==============================================================================

variable "sku_name" {
  type        = string
  description = "Application Gateway SKU. WAF_v2 enables WAF policy support; Standard_v2 is for non-WAF workloads."
  default     = "WAF_v2"

  validation {
    condition     = contains(["Standard_v2", "WAF_v2"], var.sku_name)
    error_message = "sku_name must be Standard_v2 or WAF_v2."
  }
}

variable "min_capacity" {
  type        = number
  description = "Minimum number of Application Gateway instances for autoscaling (0–100). Use 1 or higher for production."
  default     = 1

  validation {
    condition     = var.min_capacity >= 0 && var.min_capacity <= 100
    error_message = "min_capacity must be between 0 and 100."
  }
}

variable "max_capacity" {
  type        = number
  description = "Maximum number of Application Gateway instances for autoscaling (2–125). Must be greater than min_capacity."
  default     = 10

  validation {
    condition     = var.max_capacity >= 2 && var.max_capacity <= 125
    error_message = "max_capacity must be between 2 and 125."
  }
}

variable "enable_http2" {
  type        = bool
  description = "Enable HTTP/2 on the Application Gateway frontend. Improves multiplexing between client and gateway."
  default     = true
}

variable "private_ip_address" {
  type        = string
  description = "Static private IP address for an internal frontend IP configuration. Set to null (default) for public-only deployments."
  default     = null
}

# ==============================================================================
# NSG
# ==============================================================================

variable "enable_nsg" {
  type        = bool
  description = "Create and associate an NSG on the Application Gateway subnet with the required GatewayManager (65200–65535) and AzureFrontDoor.Backend (443) inbound rules."
  default     = false
}

variable "additional_nsg_rules" {
  type = list(object({
    name                       = string
    priority                   = number
    direction                  = string
    access                     = string
    protocol                   = string
    destination_port_range     = optional(string)
    destination_port_ranges    = optional(list(string))
    source_address_prefix      = string
    destination_address_prefix = optional(string, "*")
  }))
  description = "Additional inbound NSG rules to add alongside the required AppGw rules. Only used when enable_nsg = true."
  default     = []
}

# ==============================================================================
# HTTPS + TLS
# ==============================================================================

variable "enable_https" {
  type        = bool
  description = "Open frontend port 443 and apply the TLS 1.2 predefined SSL policy. Required when any http_listener uses protocol = Https."
  default     = false
}

variable "ssl_certificates" {
  type = map(object({
    data                = optional(string) # Base64-encoded PFX bundle; mutually exclusive with key_vault_secret_id.
    password            = optional(string, "")
    key_vault_secret_id = optional(string) # Key Vault certificate secret ID; requires enable_identity = true.
  }))
  description = "SSL certificates to install on the gateway. Key = certificate name referenced in http_listeners. Supply either data+password (PFX) or key_vault_secret_id (Key Vault)."
  sensitive   = true
  default     = {}
}

# ==============================================================================
# Managed identity (required for Key Vault certificate references)
# ==============================================================================

variable "enable_identity" {
  type        = bool
  description = "Attach a user-assigned managed identity so the gateway can pull certificates from Key Vault."
  default     = false
}

variable "identity_ids" {
  type        = list(string)
  description = "List of user-assigned managed identity resource IDs. Required when enable_identity = true."
  default     = []
}

variable "trusted_root_certificates" {
  type = map(object({
    data                = optional(string) # Base64 DER-encoded root certificate. Mutually exclusive with key_vault_secret_id.
    key_vault_secret_id = optional(string) # Key Vault secret ID of the root cert. Requires enable_identity = true.
  }))
  description = "Trusted root certificates for end-to-end TLS when backends present self-signed or internal CA certificates. Key = certificate name referenced in backend_http_settings trusted_root_certificate_names."
  sensitive   = true
  default     = {}
}

# ==============================================================================
# WAF
# ==============================================================================

variable "enable_waf" {
  type        = bool
  description = "Enable inline WAF configuration on a WAF_v2 gateway. Mode is hardcoded to Prevention; rule set is OWASP 3.2. Ignored when sku_name = Standard_v2 or when waf_policy_id is set."
  default     = true
}

variable "waf_policy_id" {
  type        = string
  description = "Resource ID of a standalone azurerm_web_application_firewall_policy to associate with the gateway. When set, inline waf_configuration is skipped and the standalone policy takes full control."
  default     = null
}

variable "waf_max_request_body_size_kb" {
  type        = number
  description = "Maximum request body size in KB inspected by the WAF (8–128). Only applies to inline WAF configuration (when waf_policy_id is null)."
  default     = 128

  validation {
    condition     = var.waf_max_request_body_size_kb >= 8 && var.waf_max_request_body_size_kb <= 128
    error_message = "waf_max_request_body_size_kb must be between 8 and 128."
  }
}

variable "waf_file_upload_limit_mb" {
  type        = number
  description = "Maximum file upload size in MB allowed by the WAF (1–750). Only applies to inline WAF configuration (when waf_policy_id is null)."
  default     = 100

  validation {
    condition     = var.waf_file_upload_limit_mb >= 1 && var.waf_file_upload_limit_mb <= 750
    error_message = "waf_file_upload_limit_mb must be between 1 and 750."
  }
}

# ==============================================================================
# Backends
# ==============================================================================

variable "backend_pools" {
  type = map(object({
    fqdns        = optional(list(string), [])
    ip_addresses = optional(list(string), [])
  }))
  description = "Backend address pools. Key = pool name. Provide FQDNs for app services/containers or IP addresses for VM/AKS backends."

  validation {
    condition     = length(var.backend_pools) > 0
    error_message = "At least one backend_pool must be defined."
  }
}

variable "backend_http_settings" {
  type = map(object({
    port                                = number
    protocol                            = optional(string, "Http")
    request_timeout                     = optional(number, 30)
    cookie_based_affinity               = optional(string, "Disabled")
    probe_name                          = optional(string)
    host_name                           = optional(string) # Override host header sent to backend; mutually exclusive with pick_host_name_from_backend_address = true.
    pick_host_name_from_backend_address = optional(bool, false)
    trusted_root_certificate_names      = optional(list(string), []) # Required when protocol = Https with a self-signed or internal CA cert on the backend.
  }))
  description = "Backend HTTP settings. Key = settings name referenced in request_routing_rules."

  validation {
    condition     = length(var.backend_http_settings) > 0
    error_message = "At least one backend_http_settings entry must be defined."
  }

  validation {
    condition = alltrue([
      for s in values(var.backend_http_settings) : contains(["Http", "Https"], s.protocol)
    ])
    error_message = "backend_http_settings protocol must be Http or Https."
  }

  validation {
    condition = alltrue([
      for s in values(var.backend_http_settings) : contains(["Enabled", "Disabled"], s.cookie_based_affinity)
    ])
    error_message = "backend_http_settings cookie_based_affinity must be Enabled or Disabled."
  }
}

# ==============================================================================
# Health probes
# ==============================================================================

variable "health_probes" {
  type = map(object({
    protocol                                  = optional(string, "Http")
    host                                      = optional(string)
    path                                      = optional(string, "/health")
    interval                                  = optional(number, 30)
    timeout                                   = optional(number, 30)
    unhealthy_threshold                       = optional(number, 3)
    pick_host_name_from_backend_http_settings = optional(bool, false)
    match = optional(object({
      body         = optional(string)                    # Expected response body substring (empty = any body accepted).
      status_codes = optional(list(string), ["200-399"]) # Accepted status codes, e.g. ["200", "404"] or ["200-399"].
    }))
  }))
  description = "Custom health probes. Key = probe name referenced in backend_http_settings. Omit to rely on the default gateway probe."
  default     = {}

  validation {
    condition = alltrue([
      for p in values(var.health_probes) : contains(["Http", "Https"], p.protocol)
    ])
    error_message = "health_probes protocol must be Http or Https."
  }
}

# ==============================================================================
# Listeners + routing
# ==============================================================================

variable "http_listeners" {
  type = map(object({
    protocol             = string
    host_name            = optional(string)       # Single hostname for basic virtual hosting.
    host_names           = optional(list(string)) # Multiple hostnames for multi-site SNI; mutually exclusive with host_name.
    require_sni          = optional(bool, false)  # Require SNI when multiple hostnames share a single HTTPS listener.
    ssl_certificate_name = optional(string)
  }))
  description = "HTTP listeners. Key = listener name. protocol must be Http or Https. ssl_certificate_name is required for Https listeners."

  validation {
    condition     = length(var.http_listeners) > 0
    error_message = "At least one http_listener must be defined."
  }

  validation {
    condition = alltrue([
      for l in values(var.http_listeners) : contains(["Http", "Https"], l.protocol)
    ])
    error_message = "http_listeners protocol must be Http or Https."
  }
}

variable "url_path_maps" {
  type = map(object({
    default_backend_address_pool_name  = string
    default_backend_http_settings_name = string
    path_rules = list(object({
      name                       = string
      paths                      = list(string) # e.g. ["/api/*", "/v1/*"]
      backend_address_pool_name  = string
      backend_http_settings_name = string
    }))
  }))
  description = "URL path maps for path-based routing. Key = map name referenced in request_routing_rules url_path_map_name. Use rule_type = PathBasedRouting in the corresponding routing rule."
  default     = {}
}

variable "request_routing_rules" {
  type = map(object({
    listener_name               = string
    rule_type                   = optional(string, "Basic") # Basic or PathBasedRouting.
    backend_address_pool_name   = optional(string)          # null when redirect_configuration_name or url_path_map_name is set.
    backend_http_settings_name  = optional(string)          # null when redirect_configuration_name is set.
    redirect_configuration_name = optional(string)          # For HTTP→HTTPS redirect rules.
    url_path_map_name           = optional(string)          # Required when rule_type = PathBasedRouting.
    priority                    = number
  }))
  description = "Request routing rules. Key = rule name. priority must be unique across all rules (1–20000). Use PathBasedRouting + url_path_map_name for path-based routing."

  validation {
    condition     = length(var.request_routing_rules) > 0
    error_message = "At least one request_routing_rule must be defined."
  }

  validation {
    condition = alltrue([
      for r in values(var.request_routing_rules) : r.priority >= 1 && r.priority <= 20000
    ])
    error_message = "request_routing_rules priority must be between 1 and 20000."
  }

  validation {
    condition = alltrue([
      for r in values(var.request_routing_rules) : contains(["Basic", "PathBasedRouting"], r.rule_type)
    ])
    error_message = "request_routing_rules rule_type must be Basic or PathBasedRouting."
  }
}

variable "redirect_configurations" {
  type = map(object({
    redirect_type        = optional(string, "Permanent") # Permanent (301), Found (302), SeeOther (303), Temporary (307).
    target_listener_name = optional(string)              # Redirect to another listener. Mutually exclusive with target_url.
    target_url           = optional(string)              # Redirect to an external URL. Mutually exclusive with target_listener_name.
    include_path         = optional(bool, true)
    include_query_string = optional(bool, true)
  }))
  description = "Redirect configurations. Key = redirect config name referenced in request_routing_rules. Typically used for HTTP→HTTPS (Permanent) or external URL redirects."
  default     = {}

  validation {
    condition = alltrue([
      for r in values(var.redirect_configurations) : contains(["Permanent", "Found", "SeeOther", "Temporary"], r.redirect_type)
    ])
    error_message = "redirect_configurations redirect_type must be Permanent, Found, SeeOther, or Temporary."
  }
}

# ==============================================================================
# Diagnostics
# ==============================================================================

variable "enable_diagnostics" {
  type        = bool
  description = "Send Application Gateway access, performance, and WAF firewall logs plus metrics to a Log Analytics workspace."
  default     = false
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "Log Analytics workspace resource ID. Required when enable_diagnostics = true."
  default     = null
}

# ==============================================================================
# Management lock
# ==============================================================================

variable "enable_management_lock" {
  type        = bool
  description = "Apply a CanNotDelete management lock to the Application Gateway."
  default     = false
}

# ==============================================================================
# Tags
# ==============================================================================

variable "tags" {
  type        = map(string)
  description = "Tags to apply to all Application Gateway resources."
  default     = {}
}
