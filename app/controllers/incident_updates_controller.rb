class IncidentUpdatesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_incident
  before_action :set_incident_update, only: [:show, :edit, :update, :destroy]

  def index
    @incident_updates = @incident.incident_updates.includes(:user).order(created_at: :desc)
  end

  def show
  end

  def new
    @incident_update = @incident.incident_updates.build
  end

  def create
    @incident_update = @incident.incident_updates.build(incident_update_params)
    @incident_update.user = Current.user

    if @incident_update.save
      # Create incident event for the update
      @incident.incident_events.create!(
        event_type: "update_posted",
        user: Current.user,
        data: {
          update_id: @incident_update.id,
          title: @incident_update.title,
          content: @incident_update.content,
          status: @incident_update.status
        }
      )

      # Update incident status if the update includes a status change
      if @incident_update.status.present? && @incident_update.status != @incident.status
        old_status = @incident.status
        @incident.update!(status: @incident_update.status)
        
        @incident.incident_events.create!(
          event_type: "status_changed",
          user: Current.user,
          data: {
            old_status: old_status,
            new_status: @incident.status,
            triggered_by_update: @incident_update.id
          }
        )
      end

      respond_to do |format|
        format.html { redirect_to @incident, notice: 'Update was successfully posted.' }
        format.turbo_stream
      end
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.turbo_stream { render :new, status: :unprocessable_entity }
      end
    end
  end

  def edit
  end

  def update
    if @incident_update.update(incident_update_params)
      # Create incident event for the edit
      @incident.incident_events.create!(
        event_type: "update_edited",
        user: Current.user,
        data: {
          update_id: @incident_update.id,
          changes: @incident_update.saved_changes
        }
      )

      respond_to do |format|
        format.html { redirect_to @incident, notice: 'Update was successfully edited.' }
        format.turbo_stream
      end
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.turbo_stream { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @incident_update.destroy!
    
    respond_to do |format|
      format.html { redirect_to @incident, notice: 'Update was successfully deleted.' }
      format.turbo_stream
    end
  end

  private

  def set_incident
    @incident = Current.account.incidents.find(params[:incident_id])
  end

  def set_incident_update
    @incident_update = @incident.incident_updates.find(params[:id])
  end

  def incident_update_params
    params.require(:incident_update).permit(:title, :content, :status)
  end
end