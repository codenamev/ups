class UseCasesController < ApplicationController
  layout "landing"

  private def public_action? = true

  USE_CASES = {
    "saas" => {
      title: "Status Pages for SaaS Companies",
      slug: "saas",
      headline: "Keep your SaaS customers informed",
      subheadline: "When your SaaS product has downtime, silence is the worst response. Give your customers a beautiful, real-time status page that builds trust — even when things break.",
      sections: [
        {
          heading: "Why SaaS companies need status pages",
          points: [
            "Reduce support ticket volume by 40%+ during outages",
            "Build trust with transparent communication",
            "Meet enterprise customer expectations for incident reporting",
            "Provide a professional, branded experience at status.yourapp.com"
          ]
        },
        {
          heading: "What ups.dev gives SaaS teams",
          points: [
            "Custom domain support — status.yourapp.com with SSL",
            "Email notifications to keep subscribers updated automatically",
            "Component-level status for granular reporting (API, Dashboard, Auth, etc.)",
            "Incident management with timeline updates",
            "API integration for automated status changes from your monitoring tools",
            "Subscriber management so customers opt in for updates"
          ]
        }
      ]
    },
    "api-providers" => {
      title: "Status Pages for API Providers",
      slug: "api-providers",
      headline: "Your API's trust layer",
      subheadline: "API consumers check your status page before filing a bug report. Make sure what they find is accurate, real-time, and beautifully designed.",
      sections: [
        {
          heading: "Why API providers need status pages",
          points: [
            "Developers integrate against your API — they need to know when it's down",
            "Reduce 'is your API down?' messages in your support channels",
            "Provide a machine-readable status endpoint (.json) for automated checks",
            "Document incidents and post-mortems for enterprise customers"
          ]
        },
        {
          heading: "Built for API-first companies",
          points: [
            "JSON API endpoint for each status page — integrate with anything",
            "Component-level monitoring (Auth, Webhooks, Data Processing, etc.)",
            "WebSocket real-time updates — no polling needed",
            "REST API to automate status changes from CI/CD pipelines",
            "Incident timeline with detailed update history",
            "MCP (Model Context Protocol) support for AI agent integration"
          ]
        }
      ]
    },
    "indie-hackers" => {
      title: "Status Pages for Indie Hackers & Solo Developers",
      slug: "indie-hackers",
      headline: "Professional status pages on an indie budget",
      subheadline: "You don't need enterprise pricing to look professional. Get a beautiful status page for your side project, startup, or indie SaaS — starting free.",
      sections: [
        {
          heading: "Why indie hackers use ups.dev",
          points: [
            "Free tier — 1 status page with 5 components, no credit card",
            "2-minute setup — no DevOps knowledge required",
            "Professional appearance that builds credibility with early users",
            "Shows potential customers you take reliability seriously"
          ]
        },
        {
          heading: "Perfect for bootstrapped startups",
          points: [
            "Start free, upgrade to $19/month when you're ready (not $109 like StatusPage.io)",
            "API-driven — automate status updates from your deployment scripts",
            "Beautiful default design that matches modern web standards",
            "Custom domain when you're ready for status.yourapp.com",
            "Built by an indie developer who understands the budget constraints",
            "No vendor lock-in — export your data anytime"
          ]
        }
      ]
    }
  }.freeze

  def show
    @use_case = USE_CASES[params[:use_case]]
    raise ActionController::RoutingError, "Not Found" unless @use_case
  end
end
