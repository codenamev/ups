require "test_helper"

class StatusMonitorTest < ActiveSupport::TestCase
  setup do
    @monitor = status_monitors(:one)
    @account = accounts(:one)
    @status_page = status_pages(:one)
    @component = components(:one)
    # Fixture has url: MyString which is invalid; set a proper URL for tests
    @monitor.url = "https://example.com/health"
  end

  # --- Associations ---

  test "belongs to account" do
    assert_equal @account, @monitor.account
  end

  test "belongs to status_page" do
    assert_equal @status_page, @monitor.status_page
  end

  test "belongs to component" do
    assert_equal @component, @monitor.component
  end

  test "has many monitor_summaries" do
    assert_respond_to @monitor, :monitor_summaries
  end

  # --- Enums ---

  test "check_type enum defines http" do
    @monitor.check_type = :http
    assert @monitor.check_type_http?
  end

  test "check_type enum defines https" do
    @monitor.check_type = :https
    assert @monitor.check_type_https?
  end

  test "check_type enum defines tcp" do
    @monitor.check_type = :tcp
    assert @monitor.check_type_tcp?
  end

  test "check_type enum defines ping" do
    @monitor.check_type = :ping
    assert @monitor.check_type_ping?
  end

  test "status enum defines up" do
    @monitor.status = :up
    assert @monitor.status_up?
  end

  test "status enum defines down" do
    @monitor.status = :down
    assert @monitor.status_down?
  end

  test "status enum defines unknown" do
    @monitor.status = :unknown
    assert @monitor.status_unknown?
  end

  # --- Validations ---

  test "valid with all required attributes" do
    monitor = StatusMonitor.new(
      account: @account,
      status_page: @status_page,
      component: @component,
      name: "API Monitor",
      url: "https://api.example.com/health",
      check_type: :https,
      interval_seconds: 60,
      timeout_seconds: 10,
      expected_status_code: 200
    )
    assert monitor.valid?
  end

  test "invalid without name" do
    @monitor.name = nil
    assert_not @monitor.valid?
    assert_includes @monitor.errors[:name], "can't be blank"
  end

  test "invalid with name exceeding 255 characters" do
    @monitor.name = "a" * 256
    assert_not @monitor.valid?
  end

  test "invalid without url" do
    @monitor.url = nil
    assert_not @monitor.valid?
    assert_includes @monitor.errors[:url], "can't be blank"
  end

  test "invalid with malformed url" do
    @monitor.url = "not-a-valid-url"
    assert_not @monitor.valid?
  end

  test "valid with http url" do
    @monitor.url = "http://example.com/check"
    assert @monitor.valid?
  end

  test "valid with https url" do
    @monitor.url = "https://example.com/check"
    assert @monitor.valid?
  end

  test "valid with tcp url" do
    @monitor.url = "tcp://example.com:5432"
    assert @monitor.valid?
  end

  test "invalid without check_type" do
    @monitor.check_type = nil
    assert_not @monitor.valid?
    assert_includes @monitor.errors[:check_type], "can't be blank"
  end

  # --- interval_seconds validation ---

  test "invalid with interval_seconds below 30" do
    @monitor.interval_seconds = 29
    assert_not @monitor.valid?
    assert @monitor.errors[:interval_seconds].any?
  end

  test "valid with interval_seconds at 30" do
    @monitor.interval_seconds = 30
    @monitor.timeout_seconds = 10
    assert @monitor.valid?
  end

  test "invalid with interval_seconds above 86400" do
    @monitor.interval_seconds = 86401
    assert_not @monitor.valid?
  end

  test "valid with interval_seconds at 86400" do
    @monitor.interval_seconds = 86400
    assert @monitor.valid?
  end

  # --- timeout_seconds validation ---

  test "invalid with timeout_seconds at 0" do
    @monitor.timeout_seconds = 0
    assert_not @monitor.valid?
  end

  test "valid with timeout_seconds at 1" do
    @monitor.timeout_seconds = 1
    assert @monitor.valid?
  end

  test "invalid with timeout_seconds at 60 or above" do
    @monitor.timeout_seconds = 60
    assert_not @monitor.valid?
  end

  test "valid with timeout_seconds at 59" do
    @monitor.timeout_seconds = 59
    assert @monitor.valid?
  end

  # --- expected_status_code validation (conditional) ---

  test "invalid with expected_status_code below 100 for http check" do
    @monitor.check_type = :http
    @monitor.expected_status_code = 99
    assert_not @monitor.valid?
    assert @monitor.errors[:expected_status_code].any?
  end

  test "invalid with expected_status_code at 600 for https check" do
    @monitor.check_type = :https
    @monitor.expected_status_code = 600
    assert_not @monitor.valid?
  end

  test "valid with expected_status_code at 200 for http check" do
    @monitor.check_type = :http
    @monitor.expected_status_code = 200
    assert @monitor.valid?
  end

  test "skips expected_status_code validation for tcp check" do
    @monitor.check_type = :tcp
    @monitor.expected_status_code = nil
    @monitor.url = "tcp://example.com:5432"
    assert @monitor.valid?
  end

  test "skips expected_status_code validation for ping check" do
    @monitor.check_type = :ping
    @monitor.expected_status_code = nil
    @monitor.url = "http://example.com"
    assert @monitor.valid?
  end

  # --- Custom validation: timeout < interval ---

  test "invalid when timeout_seconds >= interval_seconds" do
    @monitor.interval_seconds = 30
    @monitor.timeout_seconds = 30
    assert_not @monitor.valid?
    assert_includes @monitor.errors[:timeout_seconds], "must be less than check interval"
  end

  test "valid when timeout_seconds < interval_seconds" do
    @monitor.interval_seconds = 60
    @monitor.timeout_seconds = 30
    assert @monitor.valid?
  end

  # --- Scopes ---

  test "due_for_check includes monitors with nil last_checked_at" do
    @monitor.update_columns(last_checked_at: nil)
    assert_includes StatusMonitor.due_for_check, @monitor
  end

  test "due_for_check includes monitors with past last_checked_at" do
    @monitor.update_columns(last_checked_at: 1.day.ago)
    assert_includes StatusMonitor.due_for_check, @monitor
  end

  test "active scope excludes unknown status monitors" do
    @monitor.update_columns(status: 2) # unknown
    assert_not_includes StatusMonitor.active, @monitor
  end

  test "active scope includes up monitors" do
    @monitor.update_columns(status: 0) # up
    assert_includes StatusMonitor.active, @monitor
  end

  test "active scope includes down monitors" do
    @monitor.update_columns(status: 1) # down
    assert_includes StatusMonitor.active, @monitor
  end

  # --- Instance methods ---

  test "due_for_check? returns true when last_checked_at is nil" do
    @monitor.last_checked_at = nil
    assert @monitor.due_for_check?
  end

  test "due_for_check? returns true when last check was longer ago than interval" do
    @monitor.interval_seconds = 60
    @monitor.last_checked_at = 2.minutes.ago
    assert @monitor.due_for_check?
  end

  test "due_for_check? returns false when last check was recent" do
    @monitor.interval_seconds = 300
    @monitor.last_checked_at = 1.minute.ago
    assert_not @monitor.due_for_check?
  end

  test "next_check_at returns current time when last_checked_at is nil" do
    @monitor.last_checked_at = nil
    freeze_time do
      assert_equal Time.current, @monitor.next_check_at
    end
  end

  test "next_check_at returns last_checked_at plus interval_seconds" do
    checked_at = 5.minutes.ago
    @monitor.last_checked_at = checked_at
    @monitor.interval_seconds = 300
    assert_equal checked_at + 300.seconds, @monitor.next_check_at
  end
end
