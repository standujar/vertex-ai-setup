# ── Budget Alerts ─────────────────────────────────────────────────────────────
# Created only when both billing_account_id and budget_alert_emails are set.

locals {
  create_budget = var.billing_account_id != "" && length(var.budget_alert_emails) > 0
}

resource "google_monitoring_notification_channel" "email" {
  for_each     = local.create_budget ? toset(var.budget_alert_emails) : toset([])
  display_name = "Budget Alert — ${each.value}"
  type         = "email"

  labels = {
    email_address = each.value
  }
}

resource "google_billing_budget" "vertex_ai" {
  count           = local.create_budget ? 1 : 0
  billing_account = var.billing_account_id
  display_name    = "Vertex AI — ${var.project_id}"

  budget_filter {
    projects = ["projects/${data.google_project.current.number}"]
  }

  amount {
    specified_amount {
      currency_code = "EUR"
      units         = tostring(var.budget_amount_usd)
    }
  }

  threshold_rules {
    threshold_percent = 0.5
    spend_basis       = "CURRENT_SPEND"
  }

  threshold_rules {
    threshold_percent = 0.9
    spend_basis       = "CURRENT_SPEND"
  }

  threshold_rules {
    threshold_percent = 1.0
    spend_basis       = "FORECASTED_SPEND"
  }

  all_updates_rule {
    monitoring_notification_channels = [
      for ch in google_monitoring_notification_channel.email : ch.id
    ]
  }
}
