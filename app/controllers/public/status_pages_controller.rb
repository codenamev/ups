class Public::StatusPagesController < ActionController::Base
  protect_from_forgery with: :exception
  layout "public"
  before_action :set_status_page

  def show
    @components = @status_page.components.visible.by_position
    @recent_incidents = @status_page.incidents.limit(10)
    @overall_status = calculate_overall_status

    respond_to do |format|
      format.html
      format.json { render json: status_page_json }
    end
  end

  private

  def set_status_page
    @status_page = StatusPage.find_by!(slug: params[:slug])
  end

  def calculate_overall_status
    return "operational" if @components.empty?

    statuses = @components.pluck(:status).uniq

    return "major_outage" if statuses.include?("major_outage")
    return "partial_outage" if statuses.include?("partial_outage")
    return "degraded_performance" if statuses.include?("degraded_performance")
    return "maintenance" if statuses.include?("maintenance")

    "operational"
  end

  def status_page_json
    active_incidents = @status_page.incidents.where.not(status: "resolved").order(created_at: :desc)
    degraded_count = @components.count { |c| c.status != "operational" }

    {
      page: {
        id: @status_page.id,
        name: @status_page.name,
        slug: @status_page.slug,
        url: public_status_page_url(@status_page.slug),
        overall_status: @overall_status,
        overall_status_description: status_description(@overall_status),
        time_zone: @status_page.timezone || "UTC",
        updated_at: @status_page.updated_at.iso8601
      },
      summary: build_summary(degraded_count, active_incidents.size),
      components: @components.map do |component|
        {
          id: component.id,
          name: component.name,
          description: component.description,
          status: component.status == "maintenance" ? "under_maintenance" : component.status,
          status_changed_at: component.updated_at.iso8601,
          position: component.position,
          created_at: component.created_at.iso8601,
          updated_at: component.updated_at.iso8601
        }
      end,
      active_incidents: active_incidents.limit(10).map do |incident|
        {
          id: incident.id,
          title: incident.title,
          status: incident.status,
          impact: incident.impact,
          started_at: incident.started_at&.iso8601,
          affected_components: incident.components.map { |c| { id: c.id, name: c.name } },
          created_at: incident.created_at.iso8601,
          updated_at: incident.updated_at.iso8601,
          shortlink: incident.shortlink
        }
      end,
      recent_incidents: @recent_incidents.limit(5).map do |incident|
        {
          id: incident.id,
          title: incident.title,
          status: incident.status,
          impact: incident.impact,
          started_at: incident.started_at&.iso8601,
          resolved_at: incident.resolved_at&.iso8601,
          created_at: incident.created_at.iso8601,
          updated_at: incident.updated_at.iso8601,
          shortlink: incident.shortlink
        }
      end,
      last_updated_at: [@status_page.updated_at, *@components.map(&:updated_at)].compact.max.iso8601
    }
  end

  def build_summary(degraded_count, active_count)
    total = @components.size
    if degraded_count == 0 && active_count == 0
      "All #{total} components operational."
    else
      parts = []
      parts << "#{degraded_count} of #{total} components degraded" if degraded_count > 0
      parts << "#{active_count} active incident#{'s' if active_count != 1}" if active_count > 0
      parts.join(". ") + "."
    end
  end

  def status_description(status)
    case status
    when "operational"
      "All Systems Operational"
    when "degraded_performance"
      "Degraded Performance"
    when "partial_outage"
      "Partial System Outage"
    when "major_outage"
      "Major System Outage"
    when "maintenance"
      "Under Maintenance"
    end
  end
end
