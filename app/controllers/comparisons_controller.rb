class ComparisonsController < ApplicationController
  layout "landing"

  private def public_action? = true

  COMPETITORS = {
    "statuspage" => {
      name: "Atlassian Statuspage",
      slug: "statuspage",
      tagline: "Same features, 5x cheaper",
      price: "$109/mo",
      description: "Atlassian Statuspage is the industry standard — and the industry price tag. Starting at $109/month for basic features, it's built for enterprises with enterprise budgets.",
      pain_points: [
        "Starts at $109/month for the Business plan (was recently increased)",
        "Clunky Atlassian UI that feels like enterprise software",
        "Limited API unless you're on expensive tiers",
        "Slow onboarding — requires Atlassian account setup",
        "Design looks dated compared to modern web standards"
      ],
      ups_advantages: [
        { feature: "Starting price", competitor: "$109/month", ups: "$19/month" },
        { feature: "Setup time", competitor: "15-30 minutes", ups: "Under 2 minutes" },
        { feature: "Real-time updates", competitor: "Polling-based", ups: "WebSocket (instant)" },
        { feature: "Custom domains", competitor: "Business plan ($109+)", ups: "Included in Pro ($19)" },
        { feature: "API access", competitor: "All plans", ups: "All plans" },
        { feature: "Design", competitor: "Functional but dated", ups: "Modern, developer-focused" },
        { feature: "Free tier", competitor: "No (removed)", ups: "Yes — 1 status page, 5 components" }
      ]
    },
    "cachet" => {
      name: "Cachet",
      slug: "cachet",
      tagline: "Modern alternative to abandoned open-source",
      price: "Free (self-hosted)",
      description: "Cachet was the go-to open-source status page for years. But development has stalled, the PHP codebase is aging, and setting it up requires significant DevOps effort.",
      pain_points: [
        "Development largely abandoned (last major release years ago)",
        "Requires PHP + MySQL/PostgreSQL infrastructure",
        "No built-in monitoring — status updates are manual only",
        "Security patches are slow or nonexistent",
        "No hosted option — you maintain everything yourself"
      ],
      ups_advantages: [
        { feature: "Active development", competitor: "Stalled", ups: "Active (Rails 8)" },
        { feature: "Built-in monitoring", competitor: "No", ups: "Yes — synthetic monitoring included" },
        { feature: "Setup effort", competitor: "Hours (PHP, DB, web server)", ups: "2 minutes (hosted) or Docker deploy" },
        { feature: "Real-time updates", competitor: "Page refresh only", ups: "WebSocket (live)" },
        { feature: "Maintenance burden", competitor: "You handle everything", ups: "Zero (hosted) or minimal (self-hosted)" },
        { feature: "Email notifications", competitor: "Basic", ups: "Full subscriber management" },
        { feature: "API", competitor: "Basic REST", ups: "Full REST + MCP protocol" }
      ]
    },
    "betteruptime" => {
      name: "Better Uptime",
      slug: "betteruptime",
      tagline: "Simpler, cheaper, developer-focused",
      price: "$25/mo",
      description: "Better Uptime bundles monitoring with status pages, which sounds great — until you realize you're paying for monitoring features you might already have. If you just need a great status page, you're overpaying.",
      pain_points: [
        "Bundled pricing means paying for monitoring you may not need",
        "Status page customization is limited on lower tiers",
        "Part of a larger suite — can feel bloated for simple needs",
        "Custom domains require paid plans",
        "Less developer-focused, more aimed at ops teams"
      ],
      ups_advantages: [
        { feature: "Focus", competitor: "Monitoring suite + status pages", ups: "Status pages first, monitoring included" },
        { feature: "Starting price", competitor: "$25/month", ups: "$19/month" },
        { feature: "Custom domains", competitor: "Paid plans only", ups: "Included in Pro" },
        { feature: "API-first design", competitor: "API available", ups: "API-driven architecture" },
        { feature: "Tech stack", competitor: "Proprietary", ups: "Rails 8 + SQLite (transparent)" },
        { feature: "Free tier", competitor: "Limited", ups: "1 status page, 5 components" },
        { feature: "Setup complexity", competitor: "Moderate", ups: "2 minutes, zero config" }
      ]
    }
  }.freeze

  def show
    @competitor = COMPETITORS[params[:competitor]]
    raise ActionController::RoutingError, "Not Found" unless @competitor
  end
end
