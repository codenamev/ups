require "test_helper"
require "ostruct"

class MonitoringOrchestratorTest < ActiveSupport::TestCase
  setup do
    @account = accounts(:one)
    @status_page = status_pages(:one)
    @component = components(:one)

    @monitor = StatusMonitor.create!(
      account: @account,
      status_page: @status_page,
      component: @component,
      name: "HTTP Monitor",
      url: "https://example.com/health",
      check_type: :https,
      interval_seconds: 60,
      timeout_seconds: 30,
      expected_status_code: 200,
      status: :up
    )

    @orchestrator = MonitoringOrchestrator.new(@monitor)
    @success_result = OpenStruct.new(success?: true, error: nil, response_time_ms: 100)
    @failure_result = OpenStruct.new(success?: false, error: "Connection refused", response_time_ms: 0)
  end

  test "perform_check with successful check updates monitor status to up" do
    @monitor.update!(status: :down)

    with_stubbed_check(@success_result) do
      @orchestrator.perform_check
    end

    @monitor.reload
    assert @monitor.status_up?
    assert_not_nil @monitor.last_checked_at
  end

  test "perform_check with failed check updates monitor status to down" do
    @monitor.update!(status: :up)

    with_stubbed_check(@failure_result) do
      @orchestrator.perform_check
    end

    @monitor.reload
    assert @monitor.status_down?
  end

  test "perform_check records hourly summary" do
    with_stubbed_check(@success_result) do
      @orchestrator.perform_check
    end

    hourly = @monitor.monitor_summaries.find_by(period_type: "hour")
    assert_not_nil hourly
    assert_equal 1, hourly.checks_count
    assert_equal 1, hourly.successful_count
    assert_equal 100.0, hourly.uptime_percentage
  end

  test "perform_check records daily summary" do
    with_stubbed_check(@success_result) do
      @orchestrator.perform_check
    end

    daily = @monitor.monitor_summaries.find_by(period_type: "day")
    assert_not_nil daily
    assert_equal 1, daily.checks_count
    assert_equal 1, daily.successful_count
  end

  test "perform_check updates component status on transition from up to down" do
    @monitor.update!(status: :up)
    @component.update_column(:status, Component.statuses[:operational])

    with_stubbed_check(@failure_result) do
      @orchestrator.perform_check
    end

    @monitor.reload
    assert @monitor.status_down?, "Monitor should be marked as down"

    # Component status should change since monitor transitioned from up to down
    @component.reload
    assert_equal "partial_outage", @component.status
  end

  test "perform_check resets component status on transition from down to up" do
    @monitor.update!(status: :down)
    @component.update_column(:status, Component.statuses[:partial_outage])

    with_stubbed_check(@success_result) do
      @orchestrator.perform_check
    end

    @monitor.reload
    assert @monitor.status_up?, "Monitor should be marked as up"

    @component.reload
    assert_equal "operational", @component.status
  end

  test "perform_check handles errors gracefully" do
    # Override execute_check to raise an error
    @orchestrator.define_singleton_method(:execute_check) do
      raise StandardError, "network timeout"
    end

    with_stubbed_notifications do
      result = @orchestrator.perform_check
      assert_not result.success?
      assert_equal "network timeout", result.error
    end

    @monitor.reload
    assert @monitor.status_down?
  end

  test "status_changed detects transition from up to down" do
    @monitor.update!(status: :up)
    orchestrator = MonitoringOrchestrator.new(@monitor)

    with_stubbed_check(@failure_result) do
      result = orchestrator.perform_check
      assert_not result.success?
    end

    @monitor.reload
    assert @monitor.status_down?
  end

  test "status_changed detects no change when status stays up" do
    @monitor.update!(status: :up)
    orchestrator = MonitoringOrchestrator.new(@monitor)

    with_stubbed_check(@success_result) do
      orchestrator.perform_check
    end

    @component.reload
    assert_equal "operational", @component.status
  end

  test "record_summary calculates uptime percentage correctly" do
    with_stubbed_check(@success_result) do
      @orchestrator.perform_check
    end

    with_stubbed_check(@failure_result) do
      MonitoringOrchestrator.new(@monitor.reload).perform_check
    end

    hourly = @monitor.monitor_summaries.find_by(period_type: "hour")
    assert_equal 2, hourly.checks_count
    assert_equal 1, hourly.successful_count
    assert_equal 50.0, hourly.uptime_percentage
  end

  test "record_summary sets average response time" do
    with_stubbed_check(@success_result) do
      @orchestrator.perform_check
    end

    hourly = @monitor.monitor_summaries.find_by(period_type: "hour")
    assert_not_nil hourly.avg_response_ms
    # Duration is based on wall-clock time in perform_check, so it may be 0
    # for fast stubbed calls. Just verify the field is populated.
    assert_operator hourly.avg_response_ms, :>=, 0
  end

  private

  # Temporarily replaces HttpCheckService#call to return a canned result
  # and suppresses notification/webhook side effects.
  def with_stubbed_check(result, &block)
    original_call = HttpCheckService.instance_method(:call)
    HttpCheckService.define_method(:call) { result }

    with_stubbed_notifications(&block)
  ensure
    HttpCheckService.define_method(:call, original_call)
  end

  def with_stubbed_notifications
    original_notify = NotificationService.method(:notify_component_status_change)
    original_deliver_component = WebhookService.method(:deliver_component_status_changed)
    original_deliver_page = WebhookService.method(:deliver_page_overall_status_changed)

    NotificationService.define_singleton_method(:notify_component_status_change) { |*| nil }
    WebhookService.define_singleton_method(:deliver_component_status_changed) { |*| nil }
    WebhookService.define_singleton_method(:deliver_page_overall_status_changed) { |*| nil }

    yield
  ensure
    NotificationService.define_singleton_method(:notify_component_status_change, original_notify)
    WebhookService.define_singleton_method(:deliver_component_status_changed, original_deliver_component)
    WebhookService.define_singleton_method(:deliver_page_overall_status_changed, original_deliver_page)
  end
end
