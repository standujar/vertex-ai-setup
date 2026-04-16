# Full setup: Vertex AI + LiteLLM proxy on Cloud Run for Cursor IDE.

terraform {
  required_version = ">= 1.6"
}

module "vertex_ai" {
  source = "github.com/standujar/vertex-ai-setup"

  project_id       = "my-gcp-project"
  vertex_ai_region = "us-east5"

  vertex_ai_users = [
    "user:alice@example.com",
  ]

  enable_litellm_proxy  = true
  region                = "us-central1"
  litellm_max_instances = 2
}

output "litellm_url" {
  value = module.vertex_ai.litellm_url
}

output "litellm_master_key" {
  value     = module.vertex_ai.litellm_master_key
  sensitive = true
}

output "next_steps" {
  value = module.vertex_ai.next_steps
}
