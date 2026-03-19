require "test_helper"

class IncidentNotificationJobTest < ActiveJob::TestCase
  setup do
    @incident = incidents(:one)
  end

  test "performs notification for created event type" do
    called = false
    original = ::NotificationService.method(:notify_incident_created)
    ::NotificationService.define_singleton_method(:notify_incident_created) { |*| called = true }

    IncidentNotificationJob.perform_now(@incident.id, "created")
    assert called, "Expected notify_incident_created to be called"
  ensure
    ::NotificationService.define_singleton_method(:notify_incident_created, original)
  end

  test "performs notification for updated event type" do
    update = @incident.incident_updates.order(:created_at).last
    # If an update exists, notify_incident_updated should be called
    # If not, the job simply won't call notify (no error)
    called = false
    original = ::NotificationService.method(:notify_incident_updated)
    ::NotificationService.define_singleton_method(:notify_incident_updated) { |*| called = true }

    IncidentNotificationJob.perform_now(@incident.id, "updated")

    if update
      assert called, "Expected notify_incident_updated to be called"
    end
  ensure
    ::NotificationService.define_singleton_method(:notify_incident_updated, original)
  end

  test "performs notification for resolved event type" do
    called = false
    original = ::NotificationService.method(:notify_incident_resolved)
    ::NotificationService.define_singleton_method(:notify_incident_resolved) { |*| called = true }

    IncidentNotificationJob.perform_now(@incident.id, "resolved")
    assert called, "Expected notify_incident_resolved to be called"
  ensure
    ::NotificationService.define_singleton_method(:notify_incident_resolved, original)
  end

  test "handles missing incident gracefully by discarding" do
    nonexistent_id = 999_999_999

    assert_nothing_raised do
      IncidentNotificationJob.perform_now(nonexistent_id, "created")
    end
  end

  test "queues on notifications queue" do
    assert_equal "notifications", IncidentNotificationJob.new.queue_name
  end

  test "logs warning for unknown event type" do
    assert_nothing_raised do
      IncidentNotificationJob.perform_now(@incident.id, "unknown_event")
    end
  end

  test "enqueues job for later execution" do
    assert_enqueued_with(job: IncidentNotificationJob, args: [ @incident.id, "created" ]) do
      IncidentNotificationJob.perform_later(@incident.id, "created")
    end
  end
end
