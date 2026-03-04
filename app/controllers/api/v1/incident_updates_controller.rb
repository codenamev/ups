# API controller for managing incident updates
class Api::V1::IncidentUpdatesController < Api::BaseController
  before_action :set_status_page
  before_action :set_incident
  before_action :set_incident_update, only: [:show, :update, :destroy]

  def index
    updates = @incident.incident_updates.includes(:user).order(created_at: :desc)

    render_success(
      incident_updates: updates.map { |update| serialize_incident_update(update) }
    )
  end

  def show
    render_success(
      incident_update: serialize_incident_update(@incident_update)
    )
  end

  def create
    update = @incident.incident_updates.build(incident_update_params)
    update.user = current_user

    if update.save
      # Update the incident status if provided
      if params[:incident_update][:incident_status].present?
        @incident.update!(status: params[:incident_update][:incident_status])
      end

      render_created(
        incident_update: serialize_incident_update(update)
      )
    else
      render_validation_errors(ActiveRecord::RecordInvalid.new(update))
    end
  end

  def update
    if @incident_update.update(incident_update_params)
      # Update the incident status if provided
      if params[:incident_update][:incident_status].present?
        @incident.update!(status: params[:incident_update][:incident_status])
      end

      render_success(
        incident_update: serialize_incident_update(@incident_update)
      )
    else
      render_validation_errors(ActiveRecord::RecordInvalid.new(@incident_update))
    end
  end

  def destroy
    @incident_update.destroy!
    render_success(message: "Incident update deleted successfully")
  end

  private

  def set_status_page
    @status_page = current_account.status_pages.find(params[:status_page_id])
  end

  def set_incident
    @incident = @status_page.incidents.find(params[:incident_id])
  end

  def set_incident_update
    @incident_update = @incident.incident_updates.find(params[:id])
  end

  def incident_update_params
    params.require(:incident_update).permit(:message, :status)
  end

  def serialize_incident_update(update)
    {
      id: update.id,
      message: update.message,
      status: update.status,
      status_text: update.status&.humanize,
      incident: {
        id: update.incident.id,
        title: update.incident.title,
        status: update.incident.status
      },
      created_by: {
        id: update.user.id,
        name: update.user.name,
        email: update.user.email
      },
      created_at: update.created_at,
      updated_at: update.updated_at
    }
  end
end