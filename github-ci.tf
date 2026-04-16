# ── GitHub Actions Workload Identity Federation ──────────────────────────────
#
# Allows GitHub Actions to authenticate to GCP without service account keys.
# Uses OIDC tokens from GitHub's identity provider.
#
# Usage in GitHub Actions:
#   - uses: google-github-actions/auth@v2
#     with:
#       workload_identity_provider: ${{ secrets.GCP_WORKLOAD_IDENTITY_PROVIDER }}
#       service_account: ${{ secrets.GCP_SERVICE_ACCOUNT }}

variable "github_ci_repos" {
  description = "GitHub repos allowed to authenticate (format: org/repo)"
  type        = list(string)
  default     = ["Soulmates-Land/soulmates"]
}

# Service account for CI
resource "google_service_account" "github_ci" {
  account_id   = "soulmates-ci"
  display_name = "Soulmates CI (GitHub Actions)"
}

resource "google_project_iam_member" "github_ci_vertex" {
  project = var.project_id
  role    = "roles/aiplatform.user"
  member  = "serviceAccount:${google_service_account.github_ci.email}"
}

resource "google_project_iam_member" "github_ci_service_usage" {
  project = var.project_id
  role    = "roles/serviceusage.serviceUsageConsumer"
  member  = "serviceAccount:${google_service_account.github_ci.email}"
}

# Workload Identity Pool
resource "google_iam_workload_identity_pool" "github" {
  workload_identity_pool_id = "github-actions"
  display_name              = "GitHub Actions"
  description               = "OIDC identity pool for GitHub Actions CI/CD"
}

# Workload Identity Provider (GitHub OIDC)
resource "google_iam_workload_identity_pool_provider" "github" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-oidc"
  display_name                       = "GitHub OIDC"

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.repository" = "assertion.repository"
  }

  attribute_condition = join(" || ", [
    for repo in var.github_ci_repos :
    "assertion.repository == \"${repo}\""
  ])

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

# Allow GitHub repos to impersonate the CI service account
resource "google_service_account_iam_member" "github_ci_wif" {
  for_each           = toset(var.github_ci_repos)
  service_account_id = google_service_account.github_ci.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/${each.value}"
}
