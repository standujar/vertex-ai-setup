<p align="center">
  <h1 align="center">vertex-ai-setup</h1>
  <p align="center">
    Use your GCP credits for Claude. One <code>terraform apply</code>.<br/>
    Claude Code, Cursor, any OpenAI-compatible tool.
  </p>
  <p align="center">
    <a href="https://github.com/standujar/vertex-ai-setup/actions"><img src="https://github.com/standujar/vertex-ai-setup/actions/workflows/validate.yaml/badge.svg" alt="CI"></a>
    <a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/license-MIT-blue" alt="License"></a>
    <a href="https://registry.terraform.io"><img src="https://img.shields.io/badge/terraform-%3E%3D1.6-blueviolet" alt="Terraform"></a>
  </p>
</p>

---

You have GCP credits. Claude charges per API call. **Why not use the credits you already have?**

**vertex-ai-setup** configures everything in one command: Vertex AI API, IAM, budget alerts, and an optional [LiteLLM](https://github.com/BerriAI/litellm) proxy on Cloud Run for tools that don't speak Vertex AI natively.

Same models. Same pricing. Paid with GCP credits instead of cash.

## What you get

| Tool | How it connects | Proxy needed? |
|------|----------------|---------------|
| **Claude Code** | Direct to Vertex AI (3 env vars) | No |
| **Cursor** | Via LiteLLM proxy on Cloud Run | Yes |
| **Cline / Continue / Aider** | Via LiteLLM proxy | Yes |
| **Any OpenAI-compatible tool** | Via LiteLLM proxy | Yes |

## Getting started

### 1. Clone and configure

```bash
git clone https://github.com/standujar/vertex-ai-setup.git
cd vertex-ai-setup
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:

```hcl
project_id       = "my-gcp-project"
vertex_ai_region = "global"

vertex_ai_users = [
  "user:alice@example.com",
  "user:bob@example.com",
]

# Optional: budget alerts
billing_account_id  = "012345-6789AB-CDEF01"
budget_amount_usd   = 500
budget_alert_emails = ["alice@example.com"]

# Optional: LiteLLM proxy for Cursor & others
enable_litellm_proxy = true
```

### 2. Apply

```bash
terraform init
terraform apply
```

### 3. Enable Claude models (manual, one-time)

This is the one step Terraform can't automate — it's a console click.

1. Open [Vertex AI Model Garden](https://console.cloud.google.com/vertex-ai/model-garden)
2. Search **"Claude"**
3. Enable the models you need (Sonnet 4.6, Opus 4.6, Haiku 4.5)

### 4. Start using Claude

<details open>
<summary><strong>Claude Code</strong> (direct — no proxy)</summary>

Add to `~/.zshrc`:

```bash
export CLAUDE_CODE_USE_VERTEX=1
export CLOUD_ML_REGION=global
export ANTHROPIC_VERTEX_PROJECT_ID=my-gcp-project
```

Or `~/.claude/settings.json`:

```json
{
  "env": {
    "CLAUDE_CODE_USE_VERTEX": "1",
    "ANTHROPIC_VERTEX_PROJECT_ID": "my-gcp-project",
    "CLOUD_ML_REGION": "global"
  }
}
```

Authenticate and go:

```bash
gcloud auth application-default login
claude "hello"
```
</details>

<details>
<summary><strong>Cursor</strong> (via LiteLLM proxy)</summary>

Get your proxy URL and API key:

```bash
terraform output litellm_url
terraform output -raw litellm_master_key
```

Cursor Settings → Models → OpenAI API Key:

| Setting | Value |
|---|---|
| API Key | `<your litellm_master_key>` |
| Override OpenAI Base URL | `<your litellm_url>/v1` |
| Model | `claude-sonnet-4-6` |
</details>

<details>
<summary><strong>Cline</strong> (VS Code)</summary>

Cline settings → Provider: **OpenAI Compatible**:

| Setting | Value |
|---|---|
| Base URL | `<your litellm_url>/v1` |
| API Key | `<your litellm_master_key>` |
| Model ID | `claude-sonnet-4-6` |
</details>

<details>
<summary><strong>Aider</strong></summary>

```bash
OPENAI_API_KEY=<your litellm_master_key> \
OPENAI_API_BASE=<your litellm_url>/v1 \
aider --model claude-sonnet-4-6
```
</details>

<details>
<summary><strong>Any OpenAI-compatible tool</strong></summary>

The LiteLLM proxy exposes a standard OpenAI-compatible API:

```bash
curl <your litellm_url>/chat/completions \
  -H "Authorization: Bearer <your litellm_master_key>" \
  -H "Content-Type: application/json" \
  -d '{"model":"claude-sonnet-4-6","messages":[{"role":"user","content":"Hello!"}]}'
```
</details>

## What it deploys

| Resource | Always | Only with `enable_litellm_proxy = true` |
|----------|--------|----------------------------------------|
| Vertex AI API | ✓ | |
| IAM roles for your team | ✓ | |
| Budget alerts (email) | ✓ (if configured) | |
| Service account | | ✓ |
| Secret Manager (API key + config) | | ✓ |
| Cloud Run service (LiteLLM) | | ✓ |

The LiteLLM proxy scales to zero when idle — you only pay when it handles requests.

## Models

| Model | ID |
|-------|----|
| Claude Sonnet 4.6 | `claude-sonnet-4-6` |
| Claude Opus 4.6 | `claude-opus-4-6` |
| Claude Haiku 4.5 | `claude-haiku-4-5` |

Customize via the `litellm_models` variable.

## Pricing

Vertex AI pricing for Claude is **identical** to direct Anthropic API. The difference: you pay with **GCP credits** instead of cash.

| Model | Input / 1M tokens | Output / 1M tokens |
|-------|-------------------|---------------------|
| Opus 4.6 | $15 | $75 |
| Sonnet 4.6 | $3 | $15 |
| Haiku 4.5 | $0.80 | $4 |

## Examples

Ready-to-copy configurations in [`examples/`](examples/):

- [`basic/`](examples/basic/) — Vertex AI + IAM only (for Claude Code users)
- [`with-litellm/`](examples/with-litellm/) — + LiteLLM proxy (for Cursor)
- [`with-budget/`](examples/with-budget/) — + budget alerts

## Files

```
├── main.tf                  # APIs, IAM, service accounts
├── budget.tf                # Budget alerts (optional)
├── litellm.tf               # LiteLLM proxy on Cloud Run (optional)
├── variables.tf             # All inputs with validation
├── outputs.tf               # URLs, env vars, next steps
├── versions.tf              # Provider constraints
├── terraform.tfvars.example # Copy → terraform.tfvars
├── backend.tf.example       # Remote state template
└── examples/                # Copy-pasteable configs
```

## Cleanup

```bash
terraform destroy
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT — [LICENSE](LICENSE)

---

<p align="center">
  If this saves you money, <a href="https://github.com/standujar/vertex-ai-setup">give it a star</a>.
</p>
