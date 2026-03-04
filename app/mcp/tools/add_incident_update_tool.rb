# frozen_string_literal: true

class AddIncidentUpdateTool < ApplicationMCPTool
  tool_name "add_incident_update"
  description "Post a status update to an active incident."

  VALID_STATUSES = %w[investigating identified monitoring resolved].freeze

  property :incident_id, type: "integer", description: "Incident ID", required: true
  property :message, type: "string", description: "Update message", required: true
  property :status, type: "string", description: "New incident status (optional — updates the incident status too)"

  validates :status, inclusion: { in: VALID_STATUSES }, allow_nil: true

  def execute_tool
    incident = Incident.joins(:status_page)
                       .where(status_pages: { account_id: account.id })
                       .find(incident_id)

    update = incident.incident_updates.create!(
      title: status_title(self.status || incident.status),
      content: message,
      status: self.status || incident.status,
      user: current_user
    )

    # Update the incident status if provided
    if self.status.present? && self.status != incident.status
      incident.update!(status: self.status)
    end

    render text: {
      incident_update: {
        id: update.id,
        message: update.content,
        status: update.status,
        incident_id: incident.id,
        incident_status: incident.reload.status,
        created_at: update.created_at.iso8601
      }
    }.to_json
  end

  private

  def status_title(s)
    s&.humanize || "Update"
  end
end
