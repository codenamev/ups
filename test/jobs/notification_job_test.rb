require "test_helper"

class NotificationJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper

  setup do
    @subscriber = subscribers(:one)
    @incident = incidents(:one)
    @component = components(:one)
  end

  test "should perform incident_created notification" do
    assert_emails 1 do
      NotificationJob.perform_now("incident_created", @subscriber, @incident)
    end
  end

  test "should perform incident_updated notification" do
    assert_emails 1 do
      NotificationJob.perform_now("incident_updated", @subscriber, @incident)
    end
  end

  test "should perform incident_resolved notification" do
    assert_emails 1 do
      NotificationJob.perform_now("incident_resolved", @subscriber, @incident)
    end
  end

  test "should perform component_status_change notification" do
    old_status = "operational"
    assert_emails 1 do
      NotificationJob.perform_now("component_status_change", @subscriber, @component, old_status)
    end
  end

  test "should raise error for unknown notification type" do
    assert_raises ArgumentError do
      NotificationJob.perform_now("unknown_type", @subscriber, @incident)
    end
  end
end
