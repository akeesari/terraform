# ==============================================================================
# Application Insights
# ==============================================================================
resource "azurerm_application_insights" "this" {
  count               = var.enable_application_insights ? 1 : 0
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  application_type    = var.application_type
  workspace_id        = var.workspace_id
  retention_in_days   = var.retention_in_days
  tags                = var.tags

  # Hardcoded security defaults — never expose these as variables
  local_authentication_disabled = true

  lifecycle {
    ignore_changes = [tags["CreatedDate"], tags["LastModified"]]
  }
}
