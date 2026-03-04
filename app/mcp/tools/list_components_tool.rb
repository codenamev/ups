# frozen_string_literal: true

class ListComponentsTool < ApplicationMCPTool
  tool_name "list_components"
  description "List all components and their current statuses for a status page."

  property :page_id, type: "integer", description: "Status page ID", required: true

  def execute_tool
    page = account.status_pages.find(page_id)
    components = page.components.visible.order(:position)

    render text: {
      components: components.map { |c|
        {
          id: c.id,
          name: c.name,
          description: c.description,
          status: c.status == "maintenance" ? "under_maintenance" : c.status,
          position: c.position,
          visible: c.visible,
          updated_at: c.updated_at.iso8601
        }
      }
    }.to_json
  end
end
