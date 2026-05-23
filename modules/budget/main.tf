# ---------------------------------------------------------------------------
# Monthly budget with 50 / 80 / 100 % email alerts
# Scope: resource group
# ---------------------------------------------------------------------------
resource "azurerm_consumption_budget_resource_group" "this" {
  name              = var.name
  resource_group_id = var.resource_group_id

  amount     = var.amount
  time_grain = "Monthly"

  time_period {
    start_date = var.start_date
  }

  # --- 50 % threshold — early warning ---
  notification {
    enabled        = true
    threshold      = 50
    operator       = "GreaterThan"
    threshold_type = "Actual"
    contact_emails = var.contact_emails
  }

  # --- 80 % threshold — action required ---
  notification {
    enabled        = true
    threshold      = 80
    operator       = "GreaterThan"
    threshold_type = "Actual"
    contact_emails = var.contact_emails
  }

  # --- 100 % threshold — budget breached ---
  notification {
    enabled        = true
    threshold      = 100
    operator       = "GreaterThan"
    threshold_type = "Actual"
    contact_emails = var.contact_emails
  }

  lifecycle {
    # Amount and dates may be tuned without recreation — suppress cosmetic drift.
    ignore_changes = [time_period]
  }
}
