class IncidentWorkflow
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :incident
  attribute :current_user

  def initialize(incident, current_user: nil)
    @incident = incident
    @current_user = current_user || Current.user
  end

  def create_with_components(title:, impact:, component_ids:, initial_message:, description: nil)
    ActiveRecord::Base.transaction do
      # Create incident
      @incident.assign_attributes(
        title: title,
        impact: impact,
        status: :investigating,
        description: description,
        user: @current_user,
        account: @incident.account,
        started_at: Time.current
      )

      @incident.save!

      # Record creation event
      record_event("incident_created", {
        title: title,
        impact: impact,
        component_ids: component_ids,
        description: description
      })

      # Attach components
      component_ids.each do |component_id|
        @incident.incident_components.create!(component_id: component_id)
        record_event("component_added", { component_id: component_id })
      end

      # Update component statuses based on impact
      update_component_statuses(component_ids, impact_to_status(impact))

      # Create initial update
      @incident.incident_updates.create!(
        title: "Investigating",
        content: initial_message,
        status: :investigating,
        user: @current_user
      )

      record_event("update_posted", {
        message: initial_message,
        status: "investigating"
      })

      # Trigger notifications
      IncidentNotificationJob.perform_later(@incident.id, "created")

      @incident
    end
  rescue => error
    Rails.logger.error "IncidentWorkflow creation failed: #{error.message}"
    raise error
  end

  def transition_to(new_status, message: nil)
    return false unless valid_transition?(new_status)

    old_status = @incident.status

    ActiveRecord::Base.transaction do
      # Set resolved_at together with status to pass validation
      attrs = { status: new_status }
      attrs[:resolved_at] = Time.current if new_status.to_sym == :resolved
      @incident.update!(attrs)

      record_event("status_changed", {
        old_status: old_status,
        new_status: new_status
      })

      if message.present?
        @incident.incident_updates.create!(
          title: new_status.to_s.humanize,
          content: message,
          status: new_status,
          user: @current_user
        )

        record_event("update_posted", {
          message: message,
          status: new_status
        })
      end

      # Record resolved event
      if new_status.to_sym == :resolved
        record_event("incident_resolved", {
          resolved_at: @incident.resolved_at,
          duration_minutes: duration_in_minutes
        })
      end

      # Trigger notifications
      IncidentNotificationJob.perform_later(@incident.id, "updated")

      true
    end
  rescue => error
    Rails.logger.error "IncidentWorkflow transition failed: #{error.message}"
    false
  end

  def add_component(component_id)
    return false if @incident.component_ids.include?(component_id)

    @incident.incident_components.create!(component_id: component_id)
    record_event("component_added", { component_id: component_id })

    # Update component status if incident is ongoing
    unless @incident.status_resolved?
      component = Component.find(component_id)
      component.update!(status: impact_to_status(@incident.impact))
    end

    true
  rescue => error
    Rails.logger.error "Failed to add component to incident: #{error.message}"
    false
  end

  def remove_component(component_id)
    incident_component = @incident.incident_components.find_by(component_id: component_id)
    return false unless incident_component

    incident_component.destroy!
    record_event("component_removed", { component_id: component_id })

    # Reset component status if no other active incidents affect it
    component = Component.find(component_id)
    if component.incidents.active.where.not(id: @incident.id).empty?
      component.update!(status: :operational)
    end

    true
  rescue => error
    Rails.logger.error "Failed to remove component from incident: #{error.message}"
    false
  end

  def calculate_mttr
    return 0 unless @incident.status_resolved? && @incident.started_at && @incident.resolved_at

    duration_in_minutes
  end

  private

  def record_event(event_type, data = {})
    @incident.incident_events.create!(
      event_type: event_type,
      data: data.merge(
        user_id: @current_user.id,
        user_name: @current_user.name
      ),
      occurred_at: Time.current,
      user: @current_user
    )
  end

  def valid_transition?(new_status)
    case @incident.status.to_sym
    when :investigating
      %i[identified monitoring resolved].include?(new_status.to_sym)
    when :identified
      %i[monitoring resolved].include?(new_status.to_sym)
    when :monitoring
      %i[resolved].include?(new_status.to_sym)
    when :resolved
      false # Can't transition from resolved
    else
      false
    end
  end

  def impact_to_status(impact)
    case impact.to_sym
    when :minor then :degraded_performance
    when :major then :partial_outage
    when :critical then :major_outage
    when :maintenance then :maintenance
    else :degraded_performance
    end
  end

  def update_component_statuses(component_ids, status)
    Component.where(id: component_ids).update_all(status: status)
  end

  def duration_in_minutes
    return 0 unless @incident.started_at && @incident.resolved_at

    ((@incident.resolved_at - @incident.started_at) / 60.0).round(2)
  end
end
