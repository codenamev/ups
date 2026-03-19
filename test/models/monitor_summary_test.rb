require "test_helper"

class MonitorSummaryTest < ActiveSupport::TestCase
  setup do
    @monitor_summary = monitor_summaries(:one)
  end

  # -- Associations --

  test "belongs to status_monitor" do
    assert_respond_to @monitor_summary, :status_monitor
    assert_instance_of StatusMonitor, @monitor_summary.status_monitor
  end

  # -- Fixture sanity --

  test "fixtures are valid" do
    assert monitor_summaries(:one).valid?
    assert monitor_summaries(:two).valid?
  end

  # -- Attribute presence --

  test "has time-series attributes" do
    assert_respond_to @monitor_summary, :period_type
    assert_respond_to @monitor_summary, :period_start
    assert_respond_to @monitor_summary, :checks_count
    assert_respond_to @monitor_summary, :successful_count
    assert_respond_to @monitor_summary, :avg_response_ms
    assert_respond_to @monitor_summary, :p95_response_ms
    assert_respond_to @monitor_summary, :p99_response_ms
    assert_respond_to @monitor_summary, :uptime_percentage
  end

  test "stores numeric values for response metrics" do
    assert_kind_of Numeric, @monitor_summary.avg_response_ms
    assert_kind_of Numeric, @monitor_summary.p95_response_ms
    assert_kind_of Numeric, @monitor_summary.p99_response_ms
    assert_kind_of Numeric, @monitor_summary.uptime_percentage
  end

  test "stores integer counts" do
    assert_kind_of Integer, @monitor_summary.checks_count
    assert_kind_of Integer, @monitor_summary.successful_count
  end
end
