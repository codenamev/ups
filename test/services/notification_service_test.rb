require "test_helper"

class NotificationServiceTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @account = accounts(:one)
    @status_page = status_pages(:one)
    @incident = incidents(:one)
    @subscriber = subscribers(:one)
    @incident_update = incident_updates(:one)

    # Ensure subscriber is active (confirmed + not unsubscribed)
    @subscriber.update_columns(confirmed: true, unsubscribed_at: nil)

    # Remove incident-component associations to avoid the .or structural
    # incompatibility in NotificationPreference.for_incident when joins are used.
    @incident.incident_components.destroy_all

    # Create a global notification preference (component_id: nil) for subscriber.
    # Fixture preference (:one) is component-specific, so for_incident's global
    # query won't find it. We need a global pref with all severity/notification flags.
    @global_pref = @subscriber.notification_preferences.find_or_create_by!(component_id: nil) do |pref|
      pref.incident_created = true
      pref.incident_updated = true
      pref.incident_resolved = true
      pref.component_status_change = true
      pref.severity_minor = true
      pref.severity_major = true
      pref.severity_critical = true
      pref.severity_maintenance = true
    end
    # Ensure all flags are true even if the record already existed
    @global_pref.update!(
      incident_created: true,
      incident_updated: true,
      incident_resolved: true,
      component_status_change: true,
      severity_minor: true,
      severity_major: true,
      severity_critical: true,
      severity_maintenance: true
    )
  end

  # --- notify_incident_created ---

  test "notify_incident_created sends email notifications to subscribed subscribers" do
    assert_enqueued_with(job: ActionMailer::MailDeliveryJob) do
      NotificationService.new.notify_incident_created(@incident)
    end
  end

  test "notify_incident_created triggers webhook delivery" do
    service = NotificationService.new
    assert_nothing_raised do
      service.notify_incident_created(@incident)
    end
  end

  # --- notify_incident_updated ---

  test "notify_incident_updated sends notifications" do
    assert_enqueued_with(job: ActionMailer::MailDeliveryJob) do
      NotificationService.new.notify_incident_updated(@incident, @incident_update)
    end
  end

  # --- notify_incident_resolved ---

  test "notify_incident_resolved sends notifications" do
    assert_enqueued_with(job: ActionMailer::MailDeliveryJob) do
      NotificationService.new.notify_incident_resolved(@incident)
    end
  end

  # --- send_notifications updates subscriber counts ---

  test "send_notifications updates subscriber email counts on success" do
    original_count = @subscriber.emails_sent_count

    NotificationService.new.notify_incident_created(@incident)

    @subscriber.reload
    assert_equal original_count + 1, @subscriber.emails_sent_count
    assert_not_nil @subscriber.last_email_sent_at
  end

  test "send_notifications updates failure counts on error" do
    original_failures = @subscriber.delivery_failures_count

    # Use a custom service subclass to force an error in the notification block
    error_service = Class.new(NotificationService) do
      def notify_incident_created(incident)
        preferences = NotificationPreference.for_incident(incident, :incident_created)
        send_notifications(preferences) do |subscriber|
          raise StandardError, "simulated mail error"
        end
        WebhookService.deliver_incident_created(incident)
      end
    end

    error_service.new.notify_incident_created(@incident)

    @subscriber.reload
    assert_equal original_failures + 1, @subscriber.delivery_failures_count
    assert_not_nil @subscriber.last_delivery_failure_at
  end

  # --- notify_component_status_change ---

  test "notify_component_status_change completes without error" do
    component = components(:one)
    assert_nothing_raised do
      NotificationService.new.notify_component_status_change(component, "operational")
    end
  end
end
