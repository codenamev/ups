require "test_helper"
require "ostruct"
require_relative "../../app/services/monitoring_orchestrator"

class MonitorCheckJobTest < ActiveJob::TestCase
  setup do
    @account = accounts(:one)
    @status_page = status_pages(:one)
    @component = components(:one)

    @monitor = StatusMonitor.create!(
      account: @account,
      status_page: @status_page,
      component: @component,
      name: "Test Monitor",
      url: "https://example.com/health",
      check_type: :https,
      interval_seconds: 60,
      timeout_seconds: 30,
      expected_status_code: 200,
      status: :up
    )
  end

  test "performs monitor check for valid monitor" do
    mock_result = OpenStruct.new(success?: true, error: nil, response_time_ms: 100)

    original_call = HttpCheckService.instance_method(:call)
    HttpCheckService.define_method(:call) { mock_result }

    original_notify = NotificationService.method(:notify_component_status_change)
    NotificationService.define_singleton_method(:notify_component_status_change) { |*| nil }
    original_wh1 = WebhookService.method(:deliver_component_status_changed)
    WebhookService.define_singleton_method(:deliver_component_status_changed) { |*| nil }
    original_wh2 = WebhookService.method(:deliver_page_overall_status_changed)
    WebhookService.define_singleton_method(:deliver_page_overall_status_changed) { |*| nil }

    assert_nothing_raised do
      MonitorCheckJob.perform_now(@monitor.id)
    end

    @monitor.reload
    assert_not_nil @monitor.last_checked_at
  ensure
    HttpCheckService.define_method(:call, original_call)
    NotificationService.define_singleton_method(:notify_component_status_change, original_notify)
    WebhookService.define_singleton_method(:deliver_component_status_changed, original_wh1)
    WebhookService.define_singleton_method(:deliver_page_overall_status_changed, original_wh2)
  end

  test "handles missing monitor gracefully" do
    nonexistent_id = 999_999_999

    assert_nothing_raised do
      MonitorCheckJob.perform_now(nonexistent_id)
    end
  end

  test "queues on monitors queue" do
    assert_equal "monitors", MonitorCheckJob.new.queue_name
  end

  test "enqueues job for later execution" do
    assert_enqueued_with(job: MonitorCheckJob, args: [@monitor.id]) do
      MonitorCheckJob.perform_later(@monitor.id)
    end
  end
end
