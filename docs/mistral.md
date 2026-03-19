# Mistral Provider

[Mistral AI](https://mistral.ai) provides large language models through the Mistral platform, including models like Mistral Large, Mistral Medium, and Codestral for code generation.

## Authentication

Mistral uses API key authentication. Get your API key from the [Mistral Console](https://console.mistral.ai/api-keys).

### Environment Variable

Set the `MISTRAL_API_KEY` environment variable:

```bash
export MISTRAL_API_KEY="sk-..."
```

### Settings

You can also configure the API key in CodexBar Settings → Providers → Mistral.

## Data Source

The Mistral provider fetches usage data from the billing subscription endpoint:

- **Subscription API** (`/billing/subscription`): Returns the current plan name, monthly budget, and current month usage.

Usage percentage is calculated as `current_month_usage / monthly_budget × 100` when a budget is set.

## Display

The Mistral menu card shows:

- **Primary meter**: Monthly usage percentage (when budget is configured)
- **Identity**: Plan name and current month spending (e.g., "Build · $25.00 this month")

## CLI Usage

```bash
codexbar --provider mistral
```

## Environment Variables

| Variable | Description |
|----------|-------------|
| `MISTRAL_API_KEY` | Your Mistral API key (required) |
| `MISTRAL_API_URL` | Override the base API URL (optional, defaults to `https://api.mistral.ai/v1`) |

## Notes

- Usage data reflects the current billing period (calendar month)
- Budget limits are configured in the Mistral Console under billing settings
- Status page: [status.mistral.ai](https://status.mistral.ai) (link only, no auto-polling yet)
