# ==============================================================================
# Management Groups
# Requires tenant-level permissions (Owner or Management Group Contributor).
# Set enable_management_groups = true to provision.
# ==============================================================================

locals {
  display_name = var.display_name != "" ? var.display_name : "${var.company_name} Landing Zone"
}

resource "azurerm_management_group" "this" {
  count                      = var.enable_management_groups ? 1 : 0
  name                       = "mg-${var.company_name}"
  display_name               = local.display_name
  parent_management_group_id = var.parent_management_group_id

  subscription_ids = compact([
    var.prod_subscription_id,
    var.nonprod_subscription_id,
  ])
}
