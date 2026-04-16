# Setup with budget alerts at 50%, 90%, and 100% of monthly spend.

terraform {
  required_version = ">= 1.6"
}

module "vertex_ai" {
  source = "github.com/standujar/vertex-ai-setup"

  project_id       = "my-gcp-project"
  vertex_ai_region = "us-east5"

  vertex_ai_users = [
    "user:alice@example.com",
    "user:bob@example.com",
  ]

  billing_account_id  = "012345-6789AB-CDEF01"
  budget_amount_usd   = 1000
  budget_alert_emails = ["alerts@example.com"]
}

output "next_steps" {
  value = module.vertex_ai.next_steps
}
