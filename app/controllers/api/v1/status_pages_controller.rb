# API controller for managing status pages
class Api::V1::StatusPagesController < Api::BaseController
  before_action :set_status_page, only: [:show, :update, :destroy]

  def index
    status_pages = current_account.status_pages
                                  .includes(:components, :incidents, :page_setting)
                                  .order(created_at: :desc)

    render_success(
      status_pages: status_pages.map { |page| serialize_status_page(page) }
    )
  end

  def show
    render_success(
      status_page: serialize_status_page_with_details(@status_page)
    )
  end

  def create
    status_page = current_account.status_pages.build(status_page_params)

    if status_page.save
      render_created(
        status_page: serialize_status_page(status_page)
      )
    else
      render_validation_errors(ActiveRecord::RecordInvalid.new(status_page))
    end
  end

  def update
    if @status_page.update(status_page_params)
      render_success(
        status_page: serialize_status_page(@status_page)
      )
    else
      render_validation_errors(ActiveRecord::RecordInvalid.new(@status_page))
    end
  end

  def destroy
    @status_page.destroy!
    render_success(message: "Status page deleted successfully")
  end

  private

  def set_status_page
    @status_page = current_account.status_pages.find(params[:id])
  end

  def status_page_params
    params.require(:status_page).permit(:name, :description)
  end

  def serialize_status_page(status_page)
    {
      id: status_page.id,
      name: status_page.name,
      slug: status_page.slug,
      description: status_page.description,
      url: public_status_page_url(status_page.slug),
      timezone: status_page.timezone,
      components_count: status_page.components.count,
      incidents_count: status_page.incidents.count,
      overall_status: calculate_overall_status(status_page),
      created_at: status_page.created_at,
      updated_at: status_page.updated_at
    }
  end

  def serialize_status_page_with_details(status_page)
    base = serialize_status_page(status_page)
    base.merge(
      components: status_page.components.visible.by_position.map { |c| serialize_component(c) },
      recent_incidents: status_page.incidents.limit(10).map { |i| serialize_incident(i) }
    )
  end

  def serialize_component(component)
    {
      id: component.id,
      name: component.name,
      description: component.description,
      status: normalize_status_for_api(component.status),
      status_text: component.status.humanize,
      position: component.position,
      visible: component.visible,
      uptime_percentage: calculate_uptime_percentage(component),
      last_updated_at: component.updated_at,
      created_at: component.created_at
    }
  end

  def serialize_incident(incident)
    {
      id: incident.id,
      title: incident.title,
      description: incident.description,
      status: incident.status,
      impact: incident.impact,
      started_at: incident.started_at,
      resolved_at: incident.resolved_at,
      created_at: incident.created_at,
      updated_at: incident.updated_at
    }
  end

  def calculate_overall_status(status_page)
    components = status_page.components.visible
    return "operational" if components.empty?

    statuses = components.pluck(:status).uniq

    return "major_outage" if statuses.include?("major_outage")
    return "partial_outage" if statuses.include?("partial_outage")
    return "degraded_performance" if statuses.include?("degraded_performance")
    return "under_maintenance" if statuses.include?("maintenance")

    "operational"
  end

  def calculate_uptime_percentage(component)
    # Simplified uptime calculation - in a real system you'd calculate based on incidents/downtime
    # For now, return a static percentage based on status
    case component.status
    when "operational"
      100.0
    when "degraded_performance"
      85.0
    when "partial_outage"
      60.0
    when "major_outage"
      0.0
    when "maintenance"
      95.0
    else
      100.0
    end
  end

  def normalize_status_for_api(status)
    # Map internal status values to API standard values
    case status
    when "maintenance"
      "under_maintenance"
    else
      status
    end
  end
end