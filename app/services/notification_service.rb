class NotificationService
  def self.notify_incident_created(incident)
    new.notify_incident_created(incident)
  end

  def self.notify_incident_updated(incident, incident_update)
    new.notify_incident_updated(incident, incident_update)
  end

  def self.notify_incident_resolved(incident)
    new.notify_incident_resolved(incident)
  end

  def self.notify_component_status_change(component, old_status)
    new.notify_component_status_change(component, old_status)
  end

  def notify_incident_created(incident)
    preferences = NotificationPreference.for_incident(incident, :incident_created)
    
    send_notifications(preferences) do |subscriber|
      IncidentNotificationMailer.incident_created(subscriber, incident).deliver_later
    end
    
    # Send webhook notifications
    WebhookService.deliver_incident_created(incident)
  end

  def notify_incident_updated(incident, incident_update)
    preferences = NotificationPreference.for_incident(incident, :incident_updated)
    
    send_notifications(preferences) do |subscriber|
      IncidentNotificationMailer.incident_updated(subscriber, incident, incident_update).deliver_later
    end
    
    # Send webhook notifications
    WebhookService.deliver_incident_updated(incident)
  end

  def notify_incident_resolved(incident)
    preferences = NotificationPreference.for_incident(incident, :incident_resolved)
    
    send_notifications(preferences) do |subscriber|
      IncidentNotificationMailer.incident_resolved(subscriber, incident).deliver_later
    end
    
    # Send webhook notifications
    WebhookService.deliver_incident_resolved(incident)
  end

  def notify_component_status_change(component, old_status)
    preferences = NotificationPreference.for_component_change(component, :component_status_change)
    
    send_notifications(preferences) do |subscriber|
      # We can create a ComponentNotificationMailer later if needed
      # ComponentNotificationMailer.component_status_changed(subscriber, component, old_status).deliver_later
    end
    
    # Send webhook notifications
    WebhookService.deliver_component_status_changed(component, old_status)
  end

  private

  def send_notifications(preferences)
    subscribers = preferences.includes(:subscriber).map(&:subscriber).uniq
    
    subscribers.each do |subscriber|
      begin
        yield subscriber
        subscriber.update_columns(
          emails_sent_count: subscriber.emails_sent_count + 1,
          last_email_sent_at: Time.current
        )
        Rails.logger.info "Email notification sent to #{subscriber.email}"
      rescue => e
        subscriber.update_columns(
          delivery_failures_count: subscriber.delivery_failures_count + 1,
          last_delivery_failure_at: Time.current
        )
        Rails.logger.error "Failed to send notification to #{subscriber.email}: #{e.message}"
        # Could add error tracking/retry logic here
      end
    end
  end
end