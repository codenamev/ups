# frozen_string_literal: true

class CreateIncidentTool < ApplicationMCPTool
  tool_name "create_incident"
  description "Open a new incident on a status page."

  VALID_IMPACTS = %w[minor major critical maintenance].freeze
  VALID_STATUSES = %w[investigating identified monitoring resolved].freeze

  property :page_id, type: "integer", description: "Status page ID", required: true
  property :title, type: "string", description: "Incident title", required: true
  property :description, type: "string", description: "Initial description/message"
  property :impact, type: "string", description: "Impact level", required: true
  property :status, type: "string", description: "Initial status (default: investigating)"
  property :component_ids, type: "array", description: "IDs of affected components"

  validates :impact, inclusion: { in: VALID_IMPACTS }
  validates :status, inclusion: { in: VALID_STATUSES }, allow_nil: true

  def execute_tool
    page = account.status_pages.find(page_id)

    incident = page.incidents.build(
      title: title,
      description: description,
      impact: impact,
      status: self.status || "investigating",
      account: account,
      user: current_user,
      started_at: Time.current
    )

    if component_ids.present?
      components = page.components.where(id: component_ids)
      incident.components = components
    end

    incident.save!

    # Create initial update if description provided
    if description.present?
      incident.incident_updates.create!(
        title: title,
        content: description,
        status: incident.status,
        user: current_user
      )
    end

    render text: {
      incident: {
        id: incident.id,
        title: incident.title,
        description: incident.description,
        status: incident.status,
        impact: incident.impact,
        started_at: incident.started_at.iso8601,
        affected_components: incident.components.map { |c| { id: c.id, name: c.name } },
        created_at: incident.created_at.iso8601
      }
    }.to_json
  end
end
