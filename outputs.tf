output "vertex_ai_status" {
  description = "Confirmation that the Vertex AI API is enabled"
  value       = "Vertex AI API enabled on project ${var.project_id}. Enable Claude models manually in Model Garden."
}

output "vertex_ai_users" {
  description = "IAM members granted Vertex AI access"
  value       = var.vertex_ai_users
}

output "litellm_url" {
  description = "LiteLLM proxy URL (use as base URL in Cursor or other OpenAI-compatible clients)"
  value       = var.enable_litellm_proxy ? google_cloud_run_v2_service.litellm[0].uri : null
}

output "litellm_master_key" {
  description = "LiteLLM API key (use as Bearer token with the proxy)"
  value       = var.enable_litellm_proxy ? random_password.litellm_master_key[0].result : null
  sensitive   = true
}

output "claude_code_env" {
  description = "Environment variables for ~/.zshrc to use Claude Code with Vertex AI"
  value       = <<-EOT
    export CLAUDE_CODE_USE_VERTEX=1
    export CLOUD_ML_REGION=${var.vertex_ai_region}
    export ANTHROPIC_VERTEX_PROJECT_ID=${var.project_id}
  EOT
}

output "next_steps" {
  description = "Manual steps required after terraform apply"
  value       = <<-EOT
    1. Enable Claude models in Model Garden:
       https://console.cloud.google.com/vertex-ai/model-garden?project=${var.project_id}
       Search "Claude" and enable the models you need.

    2. Authenticate locally:
       gcloud auth application-default login

    3. Add Claude Code env vars to your shell (see claude_code_env output)

    4. ${var.enable_litellm_proxy ? "Configure Cursor with LiteLLM URL (see litellm_url output) and API key (terraform output -raw litellm_master_key)" : "LiteLLM proxy not deployed. Set enable_litellm_proxy = true if needed for Cursor."}
  EOT
}
