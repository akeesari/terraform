resource "azurerm_container_registry" "this" {
  count                     = var.enable_acr ? 1 : 0
  name                      = var.name
  resource_group_name       = var.resource_group_name
  location                  = var.location
  sku                       = var.sku
  admin_enabled             = var.admin_enabled
  quarantine_policy_enabled = var.sku == "Premium"                # quarantine policy requires Premium SKU
  export_policy_enabled     = var.sku == "Premium" ? false : true # disabling export requires Premium SKU
  tags                      = var.tags

  retention_policy_in_days = var.sku == "Premium" ? 7 : null # azurerm v4 — Premium SKU only

  # Geo-replication — Premium SKU only. Each entry creates a replica in that region.
  dynamic "georeplications" {
    for_each = var.sku == "Premium" ? toset(var.geo_replication_locations) : toset([])
    content {
      location                = georeplications.value
      zone_redundancy_enabled = true
      tags                    = var.tags
    }
  }

  lifecycle {
    precondition {
      condition     = !var.enable_network_rule_set
      error_message = "enable_network_rule_set = true is set but the azurerm_container_registry_network_rule_set resource is not yet implemented in this module. No network restriction will be applied — this would create a false sense of security. Set enable_network_rule_set = false until the implementation is complete."
    }
    ignore_changes = [
      tags["CreatedDate"],
      tags["LastModified"]
    ]
  }
}
