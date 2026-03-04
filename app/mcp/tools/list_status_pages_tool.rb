# frozen_string_literal: true

class ListStatusPagesTool < ApplicationMCPTool
  tool_name "list_status_pages"
  description "List all status pages for the authenticated account."

  def execute_tool
    pages = account.status_pages.includes(:components, :incidents, :page_setting)

    render text: {
      status_pages: pages.map { |p| serialize(p) }
    }.to_json
  end

  private

  def serialize(page)
    {
      id: page.id,
      name: page.name,
      slug: page.slug,
      description: page.description,
      timezone: page.timezone,
      overall_status: overall_status(page),
      components_count: page.components.size,
      incidents_count: page.incidents.size,
      created_at: page.created_at.iso8601,
      updated_at: page.updated_at.iso8601
    }
  end

  def overall_status(page)
    statuses = page.components.select(&:visible).map(&:status)
    return "operational" if statuses.empty?
    return "major_outage" if statuses.include?("major_outage")
    return "partial_outage" if statuses.include?("partial_outage")
    return "degraded_performance" if statuses.include?("degraded_performance")
    return "under_maintenance" if statuses.include?("maintenance")
    "operational"
  end
end
