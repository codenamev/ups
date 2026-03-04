# frozen_string_literal: true

class UpdateComponentStatusTool < ApplicationMCPTool
  tool_name "update_component_status"
  description "Update a single component's status."

  VALID_STATUSES = %w[operational degraded_performance partial_outage major_outage under_maintenance].freeze

  property :component_id, type: "integer", description: "Component ID", required: true
  property :status, type: "string", description: "New status", required: true

  validates :status, inclusion: { in: VALID_STATUSES, message: "must be one of: #{VALID_STATUSES.join(', ')}" }

  def execute_tool
    # Normalize API status to internal
    internal_status = status == "under_maintenance" ? "maintenance" : status

    component = Component.joins(:status_page)
                         .where(status_pages: { account_id: account.id })
                         .find(component_id)

    old_status = component.status
    component.update!(status: internal_status)

    render text: {
      component: {
        id: component.id,
        name: component.name,
        old_status: old_status == "maintenance" ? "under_maintenance" : old_status,
        new_status: status,
        updated_at: component.updated_at.iso8601
      }
    }.to_json
  end
end
