# frozen_string_literal: true

module Api
  module V1
    class DiscoveryController < ActionController::API
      # GET /api/v1 — capability discovery (no auth required)
      def show
        render json: {
          api_version: "v1",
          authentication: "Bearer token",
          enums: {
            component_status: %w[operational degraded_performance partial_outage major_outage under_maintenance],
            incident_status: %w[investigating identified monitoring resolved],
            incident_impact: %w[minor major critical maintenance]
          },
          rate_limit: { requests_per_minute: 60 },
          features: features_list,
          endpoints: {
            status_pages: "/api/v1/status_pages",
            public_json: "/:slug.json",
            mcp: "/mcp"
          }
        }
      end

      private

      def features_list
        features = %w[idempotency_keys webhooks structured_errors]
        features << "mcp" if defined?(ActionMCP)
        features
      end
    end
  end
end
