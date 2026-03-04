# frozen_string_literal: true

class GetStatusPageTool < ApplicationMCPTool
  tool_name "get_status_page"
  description "Get full status page details including components and recent incidents."

  property :slug, type: "string", description: "Status page slug (e.g. 'acme-cloud')", required: true

  def execute_tool
    page = account.status_pages.find_by!(slug: slug)
    components = page.components.visible.order(:position)
    incidents = page.incidents.includes(:components, :incident_updates).order(created_at: :desc).limit(10)

    render text: {
      status_page: {
        id: page.id,
        name: page.name,
        slug: page.slug,
        description: page.description,
        timezone: page.timezone,
        overall_status: overall_status(components),
        components: components.map { |c| serialize_component(c) },
        recent_incidents: incidents.map { |i| serialize_incident(i) }
      }
    }.to_json
  end

  private

  def overall_status(components)
    statuses = components.map(&:status)
    return "operational" if statuses.empty?
    return "major_outage" if statuses.include?("major_outage")
    return "partial_outage" if statuses.include?("partial_outage")
    return "degraded_performance" if statuses.include?("degraded_performance")
    return "under_maintenance" if statuses.include?("maintenance")
    "operational"
  end

  def serialize_component(c)
    {
      id: c.id,
      name: c.name,
      description: c.description,
      status: c.status == "maintenance" ? "under_maintenance" : c.status,
      position: c.position,
      updated_at: c.updated_at.iso8601
    }
  end

  def serialize_incident(i)
    {
      id: i.id,
      title: i.title,
      description: i.description,
      status: i.status,
      impact: i.impact,
      started_at: i.started_at&.iso8601,
      resolved_at: i.resolved_at&.iso8601,
      affected_components: i.components.map { |c| { id: c.id, name: c.name } },
      updates_count: i.incident_updates.size,
      created_at: i.created_at.iso8601
    }
  end
end
