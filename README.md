# Vertex AI Setup for Claude Code & Cursor

Terraform module to set up Google Cloud Vertex AI for using Claude models with your GCP credits. Supports:

- **Claude Code CLI** — direct Vertex AI connection (zero proxy needed)
- **Cursor IDE** — via optional LiteLLM proxy on Cloud Run

## What it does

- Enables the Vertex AI API on your GCP project
- Grants `roles/aiplatform.user` to your team members
- Optionally sets up budget alerts
- Optionally deploys a [LiteLLM](https://github.com/BerriAI/litellm) proxy on Cloud Run for OpenAI-compatible clients (Cursor, etc.)

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.6
- [gcloud CLI](https://cloud.google.com/sdk/docs/install) authenticated
- A GCP project with billing enabled

## Quick start

### 1. Clone and configure

```bash
git clone https://github.com/standujar/vertex-ai-setup.git
cd vertex-ai-setup
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your project ID, users, etc.
```

### 2. Apply

```bash
terraform init
terraform plan
terraform apply
```

### 3. Enable Claude models (manual, one-time)

Terraform can't automate this step — it's a console click.

1. Go to [Vertex AI Model Garden](https://console.cloud.google.com/vertex-ai/model-garden)
2. Search "Claude"
3. Enable the Claude models you need
4. Wait for approval (~24-48h)

### 4. Configure your tools

#### Claude Code CLI

```bash
# Add to ~/.zshrc or ~/.bashrc
export CLAUDE_CODE_USE_VERTEX=1
export CLOUD_ML_REGION=global
export ANTHROPIC_VERTEX_PROJECT_ID=your-project-id

# Authenticate
gcloud auth application-default login

# Verify
claude "hello"
```

Or add to `~/.claude/settings.json`:

```json
{
  "env": {
    "CLAUDE_CODE_USE_VERTEX": "1",
    "ANTHROPIC_VERTEX_PROJECT_ID": "your-project-id",
    "CLOUD_ML_REGION": "global"
  }
}
```

#### Cursor IDE (requires LiteLLM proxy)

Set `enable_litellm_proxy = true` in your `terraform.tfvars`, then re-apply.

```bash
# Get the proxy URL and API key
terraform output litellm_url
terraform output -raw litellm_master_key
```

In Cursor Settings > Models, add the LiteLLM URL as a custom OpenAI-compatible endpoint with the master key as API key.

The proxy is pre-configured with Claude models via a `config.yaml` mounted from Secret Manager. Customize which models are exposed via the `litellm_models` variable.

## Pricing

Vertex AI pricing for Claude is **identical** to direct Anthropic API pricing. The difference: you pay with **GCP credits** instead of cash.

## Files

```
.
├── main.tf                    # APIs, IAM, service accounts
├── budget.tf                  # Budget alerts (optional)
├── litellm.tf                 # LiteLLM proxy on Cloud Run (optional)
├── variables.tf               # All configurable inputs
├── outputs.tf                 # URLs, env vars, next steps
├── versions.tf                # Provider version constraints
├── terraform.tfvars.example   # Copy this to terraform.tfvars
├── backend.tf.example         # Remote state backend template
├── examples/                  # Copy-pasteable usage examples
└── .gitignore                 # Keeps secrets and state out of git
```

## Cleanup

```bash
terraform destroy
```

This does NOT disable Claude models in Model Garden (that's a manual step if needed).

## License

MIT
