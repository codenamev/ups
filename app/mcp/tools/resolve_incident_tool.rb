# frozen_string_literal: true

class ResolveIncidentTool < ApplicationMCPTool
  tool_name "resolve_incident"
  description "Resolve an incident with a closing message."

  property :incident_id, type: "integer", description: "Incident ID", required: true
  property :message, type: "string", description: "Resolution message", required: true

  def execute_tool
    incident = Incident.joins(:status_page)
                       .where(status_pages: { account_id: account.id })
                       .find(incident_id)

    if incident.status_resolved?
      report_error("Incident is already resolved.")
      return
    end

    # Create resolution update
    incident.incident_updates.create!(
      title: "Resolved",
      content: message,
      status: "resolved",
      user: current_user
    )

    # Resolve the incident
    incident.update!(status: "resolved", resolved_at: Time.current)

    render text: {
      incident: {
        id: incident.id,
        title: incident.title,
        status: "resolved",
        resolved_at: incident.resolved_at.iso8601,
        resolution_message: message
      }
    }.to_json
  end
end
