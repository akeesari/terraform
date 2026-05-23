locals {
  merged_tags = merge({
    CreatedBy = "Terraform"
  }, var.tags, var.extra_tags)
}

resource "azurerm_resource_group" "this" {
  name     = var.name
  location = var.location
  tags     = local.merged_tags

  lifecycle {
    ignore_changes = [tags["CreatedDate"], tags["LastModified"]]
  }
}

resource "azurerm_management_lock" "this" {
  count      = var.enable_management_lock ? 1 : 0
  name       = "${var.name}-lock"
  scope      = azurerm_resource_group.this.id
  lock_level = "CanNotDelete"
  notes      = "Protected by Terraform"
}
