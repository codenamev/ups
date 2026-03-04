class IncidentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_incident, only: [:show, :edit, :update, :destroy]
  before_action :set_status_page, only: [:index, :new, :create]

  def index
    @incidents = Current.account.incidents
                        .includes(:user, :status_page, :components, :incident_updates)
                        .recent
                        .order(created_at: :desc)
                        .page(params[:page])
  end

  def show
    @incident_events = @incident.incident_events.chronological.includes(:user)
    @incident_updates = @incident.incident_updates.includes(:user).order(created_at: :desc)
    @available_components = @incident.status_page.components.by_position
  end

  def new
    @incident = Current.account.incidents.build(status_page: @status_page)
    @available_components = @status_page&.components&.by_position || []
  end

  def create
    @incident = Current.account.incidents.build(incident_params)
    @incident.user = Current.user

    if @incident.save
      # Create incident_created event
      @incident.incident_events.create!(
        event_type: "incident_created",
        user: Current.user,
        data: {
          title: @incident.title,
          description: @incident.description,
          status: @incident.status,
          impact: @incident.impact,
          status_page_id: @incident.status_page_id
        }
      )

      # Add components if specified
      if params[:component_ids].present?
        component_ids = params[:component_ids].reject(&:blank?)
        component_ids.each do |component_id|
          @incident.incident_components.create!(component_id: component_id)
          @incident.incident_events.create!(
            event_type: "component_added",
            user: Current.user,
            data: { component_id: component_id }
          )
        end
      end

      redirect_to @incident, notice: 'Incident was successfully created.'
    else
      @available_components = @status_page&.components&.by_position || []
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @available_components = @incident.status_page.components.by_position
  end

  def update
    old_status = @incident.status
    old_impact = @incident.impact

    if @incident.update(incident_params)
      # Track status changes
      if @incident.saved_change_to_status?
        @incident.incident_events.create!(
          event_type: "status_changed",
          user: Current.user,
          data: {
            old_status: old_status,
            new_status: @incident.status
          }
        )
      end

      # Handle component changes
      if params[:component_ids].present?
        new_component_ids = params[:component_ids].reject(&:blank?).map(&:to_i)
        current_component_ids = @incident.components.pluck(:id)

        # Remove components
        (current_component_ids - new_component_ids).each do |component_id|
          @incident.incident_components.where(component_id: component_id).destroy_all
          @incident.incident_events.create!(
            event_type: "component_removed",
            user: Current.user,
            data: { component_id: component_id }
          )
        end

        # Add new components
        (new_component_ids - current_component_ids).each do |component_id|
          @incident.incident_components.create!(component_id: component_id)
          @incident.incident_events.create!(
            event_type: "component_added",
            user: Current.user,
            data: { component_id: component_id }
          )
        end
      end

      redirect_to @incident, notice: 'Incident was successfully updated.'
    else
      @available_components = @incident.status_page.components.by_position
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @incident.destroy!
    redirect_to incidents_url, notice: 'Incident was successfully deleted.'
  end

  private

  def set_incident
    @incident = Current.account.incidents.find(params[:id])
  end

  def set_status_page
    @status_page = Current.account.status_pages.find(params[:status_page_id]) if params[:status_page_id]
  end

  def incident_params
    params.require(:incident).permit(:title, :description, :status, :impact, :status_page_id)
  end
end