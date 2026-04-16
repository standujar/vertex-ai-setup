# Basic setup: Vertex AI API + IAM for Claude Code users.

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
}

output "claude_code_env" {
  value = module.vertex_ai.claude_code_env
}
