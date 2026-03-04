# API controller for managing components
class Api::V1::ComponentsController < Api::BaseController
  before_action :set_status_page
  before_action :set_component, only: [:show, :update, :destroy]

  def index
    components = @status_page.components.visible.by_position

    render_success(
      components: components.map { |component| serialize_component(component) }
    )
  end

  def show
    render_success(
      component: serialize_component(@component)
    )
  end

  def create
    component = @status_page.components.build(component_params)
    component.account = current_account

    if component.save
      render_created(
        component: serialize_component(component)
      )
    else
      render_validation_errors(ActiveRecord::RecordInvalid.new(component))
    end
  end

  # This is the "money endpoint" - update component status
  def update
    old_status = @component.status

    if @component.update(component_params)
      # Log the status change for audit purposes
      log_status_change(old_status, @component.status) if @component.status != old_status

      render_success(
        component: serialize_component(@component),
        message: status_change_message(old_status, @component.status)
      )
    else
      render_validation_errors(ActiveRecord::RecordInvalid.new(@component))
    end
  end

  def destroy
    @component.destroy!
    render_success(message: "Component deleted successfully")
  end

  private

  def set_status_page
    @status_page = current_account.status_pages.find(params[:status_page_id])
  end

  def set_component
    @component = @status_page.components.find(params[:id])
  end

  def component_params
    permitted_params = params.require(:component).permit(:name, :description, :status, :position, :visible)
    
    # Normalize API status values to internal values
    if permitted_params[:status].present?
      permitted_params[:status] = normalize_status_from_api(permitted_params[:status])
    end
    
    permitted_params
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
      created_at: component.created_at,
      status_page: {
        id: component.status_page.id,
        name: component.status_page.name,
        slug: component.status_page.slug
      }
    }
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

  def log_status_change(old_status, new_status)
    # Create a status update record for audit trail
    @component.status_updates.create!(
      status: new_status,
      previous_status: old_status,
      created_by: current_user.name,
      note: "Status updated via API by #{current_user.name}"
    )
  rescue => e
    # Don't fail the request if logging fails
    Rails.logger.error "Failed to log status change: #{e.message}"
  end

  def status_change_message(old_status, new_status)
    return nil if old_status == new_status

    "Component status changed from #{old_status.humanize} to #{new_status.humanize}"
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

  def normalize_status_from_api(status)
    # Map API status values to internal values
    case status
    when "under_maintenance"
      "maintenance"
    else
      status
    end
  end
end