# ── LiteLLM Proxy on Cloud Run ────────────────────────────────────────────────
#
# Deploys a LiteLLM proxy that fronts Vertex AI with an OpenAI-compatible API.
# LiteLLM requires a config.yaml with model definitions — we store it in
# Secret Manager and mount it into the container via Cloud Run volumes.

resource "random_password" "litellm_master_key" {
  count   = var.enable_litellm_proxy ? 1 : 0
  length  = 42
  special = false
}

# ── Secrets ───────────────────────────────────────────────────────────────────

resource "google_secret_manager_secret" "litellm_key" {
  count     = var.enable_litellm_proxy ? 1 : 0
  secret_id = "litellm-master-key"

  replication {
    auto {}
  }

  depends_on = [google_project_service.secret_manager[0]]
}

resource "google_secret_manager_secret_version" "litellm_key" {
  count       = var.enable_litellm_proxy ? 1 : 0
  secret      = google_secret_manager_secret.litellm_key[0].id
  secret_data = random_password.litellm_master_key[0].result
}

resource "google_secret_manager_secret" "litellm_config" {
  count     = var.enable_litellm_proxy ? 1 : 0
  secret_id = "litellm-config"

  replication {
    auto {}
  }

  depends_on = [google_project_service.secret_manager[0]]
}

resource "google_secret_manager_secret_version" "litellm_config" {
  count  = var.enable_litellm_proxy ? 1 : 0
  secret = google_secret_manager_secret.litellm_config[0].id
  secret_data = yamlencode({
    model_list = [
      for m in var.litellm_models : {
        model_name = m.name
        litellm_params = {
          model           = m.model
          vertex_project  = var.project_id
          vertex_location = var.vertex_ai_region
        }
      }
    ]
  })
}

resource "google_secret_manager_secret_iam_member" "litellm_key_access" {
  count     = var.enable_litellm_proxy ? 1 : 0
  secret_id = google_secret_manager_secret.litellm_key[0].secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.litellm[0].email}"
}

resource "google_secret_manager_secret_iam_member" "litellm_config_access" {
  count     = var.enable_litellm_proxy ? 1 : 0
  secret_id = google_secret_manager_secret.litellm_config[0].secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.litellm[0].email}"
}

# ── Cloud Run Service ─────────────────────────────────────────────────────────

resource "google_cloud_run_v2_service" "litellm" {
  count               = var.enable_litellm_proxy ? 1 : 0
  name                = "litellm-proxy"
  location            = var.region
  deletion_protection = false

  template {
    service_account = google_service_account.litellm[0].email

    scaling {
      min_instance_count = 0
      max_instance_count = var.litellm_max_instances
    }

    volumes {
      name = "litellm-config"
      secret {
        secret = google_secret_manager_secret.litellm_config[0].secret_id
        items {
          version = "latest"
          path    = "config.yaml"
        }
      }
    }

    containers {
      image = var.litellm_image
      args  = ["--config", "/app/config/config.yaml"]

      ports {
        container_port = 4000
      }

      env {
        name = "LITELLM_MASTER_KEY"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.litellm_key[0].secret_id
            version = "latest"
          }
        }
      }

      volume_mounts {
        name       = "litellm-config"
        mount_path = "/app/config"
      }

      resources {
        limits = {
          cpu    = "1"
          memory = "1Gi"
        }
      }
    }
  }

  depends_on = [
    google_project_service.cloud_run[0],
    google_secret_manager_secret_version.litellm_key[0],
    google_secret_manager_secret_version.litellm_config[0],
  ]
}

# Allow unauthenticated access — the proxy handles auth via LITELLM_MASTER_KEY.
resource "google_cloud_run_v2_service_iam_member" "litellm_invoker" {
  count    = var.enable_litellm_proxy ? 1 : 0
  name     = google_cloud_run_v2_service.litellm[0].name
  location = var.region
  role     = "roles/run.invoker"
  member   = "allUsers"
}
