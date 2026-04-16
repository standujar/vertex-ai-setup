variable "project_id" {
  description = "GCP project ID where Vertex AI and resources will be created"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "project_id must be 6-30 lowercase letters, digits, or hyphens, starting with a letter."
  }
}

variable "region" {
  description = "GCP region for Cloud Run deployment (can differ from vertex_ai_region)"
  type        = string
  default     = "us-central1"

  validation {
    condition     = can(regex("^[a-z]+-[a-z]+[0-9]$", var.region))
    error_message = "region must be a valid GCP region (e.g. us-central1, europe-west1)."
  }
}

variable "vertex_ai_region" {
  description = "Region where Claude models are available on Vertex AI (see Model Garden for current availability)"
  type        = string
  default     = "us-east5"

  validation {
    condition     = var.vertex_ai_region == "global" || can(regex("^[a-z]+-[a-z]+[0-9]$", var.vertex_ai_region))
    error_message = "vertex_ai_region must be 'global' or a valid GCP region (e.g. us-east5, europe-west1)."
  }
}

variable "billing_account_id" {
  description = "GCP billing account ID for budget alerts (format: XXXXXX-XXXXXX-XXXXXX). Leave empty to skip budget creation."
  type        = string
  default     = ""

  validation {
    condition     = var.billing_account_id == "" || can(regex("^[0-9A-F]{6}-[0-9A-F]{6}-[0-9A-F]{6}$", var.billing_account_id))
    error_message = "billing_account_id must be in format XXXXXX-XXXXXX-XXXXXX (hex characters) or empty."
  }
}

variable "budget_amount_usd" {
  description = "Monthly budget amount in USD that triggers alerts at 50%, 90%, and 100%"
  type        = number
  default     = 500

  validation {
    condition     = var.budget_amount_usd > 0
    error_message = "budget_amount_usd must be greater than 0."
  }
}

variable "budget_alert_emails" {
  description = "Email addresses that receive budget alert notifications"
  type        = list(string)
  default     = []
}

variable "vertex_ai_users" {
  description = "IAM members granted roles/aiplatform.user (e.g. [\"user:alice@example.com\", \"group:team@example.com\"])"
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for m in var.vertex_ai_users : can(regex("^(user|group|serviceAccount|domain):", m))])
    error_message = "Each member must start with user:, group:, serviceAccount:, or domain:."
  }
}

variable "enable_litellm_proxy" {
  description = "Deploy a LiteLLM proxy on Cloud Run for OpenAI-compatible clients (Cursor IDE, etc.)"
  type        = bool
  default     = false
}

variable "litellm_image" {
  description = "Docker image for the LiteLLM proxy container"
  type        = string
  default     = "docker.io/litellm/litellm:v1.83.3-stable"
}

variable "litellm_max_instances" {
  description = "Maximum number of Cloud Run instances for the LiteLLM proxy"
  type        = number
  default     = 2

  validation {
    condition     = var.litellm_max_instances >= 1 && var.litellm_max_instances <= 100
    error_message = "litellm_max_instances must be between 1 and 100."
  }
}

variable "litellm_models" {
  description = "Claude models to expose through the LiteLLM proxy. Each entry needs a name (exposed to clients) and a Vertex AI model ID."
  type = list(object({
    name  = string
    model = string
  }))
  default = [
    { name = "claude-sonnet-4-6", model = "vertex_ai/claude-sonnet-4-6" },
    { name = "claude-opus-4-6", model = "vertex_ai/claude-opus-4-6" },
    { name = "claude-haiku-4-5", model = "vertex_ai/claude-haiku-4-5" },
  ]
}
