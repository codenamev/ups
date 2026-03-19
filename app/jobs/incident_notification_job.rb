class IncidentNotificationJob < ApplicationJob
  queue_as :notifications

  retry_on StandardError, wait: :exponentially_longer, attempts: 5
  discard_on ActiveRecord::RecordNotFound

  def perform(incident_id, event_type)
    incident = Incident.find(incident_id)
    NotificationService.new.deliver_all(incident, event_type)
  rescue ActiveRecord::RecordNotFound
    Rails.logger.warn "Incident #{incident_id} not found, skipping notification"
    # Don't retry for missing records
  rescue => error
    Rails.logger.error "Incident notification failed for #{incident_id}, event: #{event_type}, error: #{error.message}"
    raise error
  end

  private

  class NotificationService
    def deliver_all(incident, event_type)
      case event_type.to_s
      when "created"
        ::NotificationService.notify_incident_created(incident)
      when "updated"
        # Find the latest incident update
        latest_update = incident.incident_updates.order(:created_at).last
        ::NotificationService.notify_incident_updated(incident, latest_update) if latest_update
      when "resolved"
        ::NotificationService.notify_incident_resolved(incident)
      else
        Rails.logger.warn "Unknown incident notification event type: #{event_type}"
      end
    end
  end
end
