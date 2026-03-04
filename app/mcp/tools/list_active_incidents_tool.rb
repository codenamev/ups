# frozen_string_literal: true

class ListActiveIncidentsTool < ApplicationMCPTool
  tool_name "list_active_incidents"
  description "List all unresolved incidents for a status page."

  property :page_id, type: "integer", description: "Status page ID", required: true

  def execute_tool
    page = account.status_pages.find(page_id)
    incidents = page.incidents.active
                    .includes(:components, :incident_updates)
                    .order(created_at: :desc)

    render text: {
      active_incidents: incidents.map { |i|
        {
          id: i.id,
          title: i.title,
          description: i.description,
          status: i.status,
          impact: i.impact,
          started_at: i.started_at&.iso8601,
          affected_components: i.components.map { |c| { id: c.id, name: c.name } },
          updates_count: i.incident_updates.size,
          created_at: i.created_at.iso8601
        }
      }
    }.to_json
  end
end
