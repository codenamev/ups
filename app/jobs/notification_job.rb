class NotificationJob < ApplicationJob
  queue_as :default

  def perform(notification_type, subscriber, resource, *args)
    case notification_type
    when 'incident_created'
      NotificationMailer.incident_created(subscriber, resource).deliver_now
    when 'incident_updated'
      NotificationMailer.incident_updated(subscriber, resource).deliver_now
    when 'incident_resolved'
      NotificationMailer.incident_resolved(subscriber, resource).deliver_now
    when 'component_status_change'
      old_status = args.first
      NotificationMailer.component_status_change(subscriber, resource, old_status).deliver_now
    else
      raise ArgumentError, "Unknown notification type: #{notification_type}"
    end
  rescue => e
    Rails.logger.error "Failed to send #{notification_type} notification to #{subscriber.email}: #{e.message}"
    raise
  end
end
