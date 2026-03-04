# API controller for managing incidents
class Api::V1::IncidentsController < Api::BaseController
  before_action :set_status_page
  before_action :set_incident, only: [:show, :update, :destroy]

  def index
    incidents = @status_page.incidents.includes(:components, :incident_updates, :user)
                           .order(created_at: :desc)
                           .limit(params[:limit] || 50)

    render_success(
      incidents: incidents.map { |incident| serialize_incident(incident) }
    )
  end

  def show
    render_success(
      incident: serialize_incident_with_details(@incident)
    )
  end

  def create
    incident = @status_page.incidents.build(incident_params)
    incident.account = current_account
    incident.user = current_user

    if incident.save
      # Create initial incident update
      incident.incident_updates.create!(
        message: incident.description,
        status: incident.status,
        user: current_user
      ) if incident.description.present?

      render_created(
        incident: serialize_incident_with_details(incident)
      )
    else
      render_validation_errors(ActiveRecord::RecordInvalid.new(incident))
    end
  end

  def update
    old_status = @incident.status

    if @incident.update(incident_params)
      # Create incident update if status changed or message provided
      if params[:incident][:update_message].present? || @incident.status != old_status
        create_incident_update(old_status)
      end

      render_success(
        incident: serialize_incident_with_details(@incident),
        message: status_change_message(old_status, @incident.status)
      )
    else
      render_validation_errors(ActiveRecord::RecordInvalid.new(@incident))
    end
  end

  def destroy
    @incident.destroy!
    render_success(message: "Incident deleted successfully")
  end

  private

  def set_status_page
    @status_page = current_account.status_pages.find(params[:status_page_id])
  end

  def set_incident
    @incident = @status_page.incidents.find(params[:id])
  end

  def incident_params
    params.require(:incident).permit(
      :title, :description, :status, :impact, :started_at, :resolved_at,
      component_ids: []
    )
  end

  def serialize_incident(incident)
    {
      id: incident.id,
      title: incident.title,
      description: incident.description,
      status: incident.status,
      status_text: incident.status.humanize,
      impact: incident.impact,
      impact_text: incident.impact.humanize,
      started_at: incident.started_at,
      resolved_at: incident.resolved_at,
      duration_minutes: calculate_duration_minutes(incident),
      components: incident.components.map { |c| serialize_incident_component(c) },
      created_by: {
        id: incident.user.id,
        name: incident.user.name,
        email: incident.user.email
      },
      updates_count: incident.incident_updates.count,
      shortlink: incident.shortlink,
      created_at: incident.created_at,
      updated_at: incident.updated_at
    }
  end

  def serialize_incident_with_details(incident)
    base = serialize_incident(incident)
    base.merge(
      updates: incident.incident_updates.includes(:user).order(created_at: :desc).map do |update|
        serialize_incident_update(update)
      end
    )
  end

  def serialize_incident_component(component)
    {
      id: component.id,
      name: component.name,
      status: component.status
    }
  end

  def serialize_incident_update(update)
    {
      id: update.id,
      message: update.message,
      status: update.status,
      status_text: update.status&.humanize,
      created_by: {
        id: update.user.id,
        name: update.user.name,
        email: update.user.email
      },
      created_at: update.created_at
    }
  end

  def calculate_duration_minutes(incident)
    return nil unless incident.started_at

    end_time = incident.resolved_at || Time.current
    ((end_time - incident.started_at) / 1.minute).round
  end

  def create_incident_update(old_status)
    update_message = params[:incident][:update_message] || 
                    default_status_message(@incident.status, old_status)

    @incident.incident_updates.create!(
      message: update_message,
      status: @incident.status,
      user: current_user
    )
  rescue => e
    # Don't fail the request if incident update creation fails
    Rails.logger.error "Failed to create incident update: #{e.message}"
  end

  def default_status_message(new_status, old_status)
    case new_status
    when "investigating"
      "We are investigating this issue."
    when "identified"
      "We have identified the cause and are working on a fix."
    when "monitoring"
      "A fix has been implemented and we are monitoring the situation."
    when "resolved"
      "This incident has been resolved."
    else
      "Incident status updated from #{old_status.humanize} to #{new_status.humanize}."
    end
  end

  def status_change_message(old_status, new_status)
    return nil if old_status == new_status

    "Incident status changed from #{old_status.humanize} to #{new_status.humanize}"
  end
end