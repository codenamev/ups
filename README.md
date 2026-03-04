# ups

Modern status pages built with Rails 8 + SQLite.

A complete, self-hostable status page platform for your web services, APIs, and infrastructure. Beautiful public status pages, incident management, subscriber notifications, synthetic monitoring, and a full REST API — all in a single Rails app backed by SQLite.

## Features

- **Status Pages** — Public, branded pages at `/your-slug` showing real-time component status
- **Components** — Track individual services with operational/degraded/partial outage/major outage/maintenance states
- **Incidents** — Create, update, and resolve incidents with full timeline history
- **Subscriber Notifications** — Email alerts when components change status or incidents are posted
- **Synthetic Monitoring** — HTTP/HTTPS/TCP health checks with configurable intervals
- **REST API** — Full CRUD API with token authentication for programmatic management
- **MCP Server** — Model Context Protocol endpoint for AI agent integration
- **Webhooks** — Outbound webhook delivery for integrating with your existing tooling
- **Real-time Updates** — Turbo Streams push status changes to connected browsers instantly
- **Multi-tenant** — Multiple accounts, status pages, and team members
- **Magic Link Auth** — Passwordless authentication via email

## Tech Stack

- **Ruby 4.0.1** / **Rails 8.1**
- **SQLite** with Solid Queue, Solid Cache, and Solid Cable
- **Tailwind CSS** / **Turbo** / **Stimulus**
- **Kamal** for zero-downtime deployments
- **Resend** for transactional email (configurable)

## Quick Start

### Docker

```bash
docker run -d \
  -p 3000:3000 \
  -v ups_storage:/rails/storage \
  -e RAILS_MASTER_KEY=your-master-key \
  ghcr.io/codenamev/ups:latest
```

### Manual Setup

```bash
git clone https://github.com/codenamev/ups.git
cd ups
bundle install
bin/rails db:create db:migrate
bin/rails server
```

Visit `http://localhost:3000`, create an account, and set up your first status page.

### Deploy with Kamal

```bash
cp config/deploy.yml.example config/deploy.yml
cp .kamal/secrets.example .kamal/secrets
# Edit both files with your server details
bin/kamal setup
```

See `config/deploy.yml.example` for a full configuration reference.

## API

All endpoints require a Bearer token (create one in the dashboard under API Tokens).

```bash
# List components
curl -H "Authorization: Bearer YOUR_TOKEN" \
  https://your-instance.com/api/v1/status_pages/your-slug/components

# Report an incident
curl -X POST \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"incident": {"title": "API Degradation", "impact": "minor"}}' \
  https://your-instance.com/api/v1/status_pages/your-slug/incidents
```

Discovery endpoint at `/api/v1` describes all available resources.

## MCP (Model Context Protocol)

ups includes an MCP server endpoint at `/mcp`, allowing AI agents to query and manage status pages programmatically. See the [ActionMCP documentation](https://github.com/seuros/action_mcp) for client integration details.

## Configuration

Environment variables:

| Variable | Description | Default |
|----------|-------------|---------|
| `RAILS_MASTER_KEY` | Decrypts `config/credentials.yml.enc` | Required |
| `HOST_URL` | Public URL for email links | `http://localhost:3000` |
| `SOLID_QUEUE_IN_PUMA` | Run background jobs in web process | `true` |
| `WEB_CONCURRENCY` | Puma worker count | `1` |

Email delivery is configured via Rails credentials. See `config/credentials.yml.enc` (edit with `bin/rails credentials:edit`).

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

[AGPL-3.0](LICENSE) — you're free to self-host, modify, and distribute. If you offer ups as a hosted service, your modifications must also be open-sourced under AGPL-3.0.
