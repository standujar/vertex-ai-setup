provider "google" {
  project               = var.project_id
  region                = var.region
  billing_project       = var.project_id
  user_project_override = true
}

data "google_project" "current" {
  project_id = var.project_id
}

# ── APIs ──────────────────────────────────────────────────────────────────────

resource "google_project_service" "vertex_ai" {
  service            = "aiplatform.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "cloud_run" {
  count              = var.enable_litellm_proxy ? 1 : 0
  service            = "run.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "secret_manager" {
  count              = var.enable_litellm_proxy ? 1 : 0
  service            = "secretmanager.googleapis.com"
  disable_on_destroy = false
}

# ── IAM ───────────────────────────────────────────────────────────────────────

resource "google_project_iam_member" "vertex_ai_user" {
  for_each = toset(var.vertex_ai_users)
  project  = var.project_id
  role     = "roles/aiplatform.user"
  member   = each.value
}

# ── Service Account for LiteLLM ──────────────────────────────────────────────

resource "google_service_account" "litellm" {
  count        = var.enable_litellm_proxy ? 1 : 0
  account_id   = "litellm-proxy"
  display_name = "LiteLLM Vertex AI Proxy"
}

resource "google_project_iam_member" "litellm_vertex" {
  count   = var.enable_litellm_proxy ? 1 : 0
  project = var.project_id
  role    = "roles/aiplatform.user"
  member  = "serviceAccount:${google_service_account.litellm[0].email}"
}

resource "google_project_iam_member" "litellm_service_usage" {
  count   = var.enable_litellm_proxy ? 1 : 0
  project = var.project_id
  role    = "roles/serviceusage.serviceUsageConsumer"
  member  = "serviceAccount:${google_service_account.litellm[0].email}"
}
