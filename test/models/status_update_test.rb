require "test_helper"

class StatusUpdateTest < ActiveSupport::TestCase
  def setup
    @status_update = status_updates(:scheduled_maintenance)
    @component = components(:one)
    @user = users(:one)
    @account = accounts(:one)
  end

  test "should be valid with valid attributes" do
    assert @status_update.valid?
  end

  test "should require title" do
    @status_update.title = nil
    assert_not @status_update.valid?
    assert_includes @status_update.errors[:title], "can't be blank"
  end

  test "should require message" do
    @status_update.message = nil
    assert_not @status_update.valid?
    assert_includes @status_update.errors[:message], "can't be blank"
  end

  test "should require scheduled_for" do
    @status_update.scheduled_for = nil
    assert_not @status_update.valid?
    assert_includes @status_update.errors[:scheduled_for], "can't be blank"
  end

  test "should require estimated_duration" do
    @status_update.estimated_duration = nil
    assert_not @status_update.valid?
    assert_includes @status_update.errors[:estimated_duration], "can't be blank"
  end

  test "should not allow estimated_duration less than 15 minutes" do
    @status_update.estimated_duration = 10
    assert_not @status_update.valid?
    assert_includes @status_update.errors[:estimated_duration], "must be between 15 minutes and 48 hours"
  end

  test "should not allow estimated_duration more than 48 hours" do
    @status_update.estimated_duration = 3000 # > 48 hours (2880 minutes)
    assert_not @status_update.valid?
    assert_includes @status_update.errors[:estimated_duration], "must be between 15 minutes and 48 hours"
  end

  test "should not allow scheduled_for in the past for new records" do
    status_update = StatusUpdate.new(
      title: "Test Maintenance",
      message: "Test message",
      scheduled_for: 1.hour.ago,
      estimated_duration: 60,
      component: @component,
      user: @user,
      account: @account
    )

    assert_not status_update.valid?
    assert_includes status_update.errors[:scheduled_for], "must be in the future"
  end

  test "should limit title length" do
    @status_update.title = "a" * 256
    assert_not @status_update.valid?
    assert_includes @status_update.errors[:title], "is too long (maximum is 255 characters)"
  end

  test "should limit message length" do
    @status_update.message = "a" * 2001
    assert_not @status_update.valid?
    assert_includes @status_update.errors[:message], "is too long (maximum is 2000 characters)"
  end

  test "should have correct status enum values" do
    assert_equal 0, StatusUpdate.statuses[:scheduled]
    assert_equal 1, StatusUpdate.statuses[:in_progress]
    assert_equal 2, StatusUpdate.statuses[:completed]
    assert_equal 3, StatusUpdate.statuses[:canceled]
  end

  test "should respond to status predicates" do
    @status_update.status = :scheduled
    assert @status_update.status_scheduled?
    assert_not @status_update.status_in_progress?

    @status_update.status = :in_progress
    assert @status_update.status_in_progress?
    assert_not @status_update.status_scheduled?
  end

  test "duration_in_hours should convert minutes to hours" do
    @status_update.estimated_duration = 120
    assert_equal 2.0, @status_update.duration_in_hours

    @status_update.estimated_duration = 90
    assert_equal 1.5, @status_update.duration_in_hours
  end

  test "estimated_end_time should calculate end time correctly" do
    scheduled_time = 2.hours.from_now.change(usec: 0) # Remove microseconds for consistent comparison
    @status_update.scheduled_for = scheduled_time
    @status_update.estimated_duration = 120 # 2 hours

    expected_end = scheduled_time + 2.hours
    assert_equal expected_end, @status_update.estimated_end_time
  end

  test "active? should return true for scheduled and in_progress" do
    @status_update.status = :scheduled
    assert @status_update.active?

    @status_update.status = :in_progress
    assert @status_update.active?

    @status_update.status = :completed
    assert_not @status_update.active?

    @status_update.status = :canceled
    assert_not @status_update.active?
  end

  test "shortlink should generate correct path" do
    status_page = @status_update.component.status_page
    expected_shortlink = "#{status_page.slug}/maintenance/#{@status_update.id}"
    assert_equal expected_shortlink, @status_update.shortlink
  end

  test "upcoming scope should return future maintenance" do
    future_updates = StatusUpdate.upcoming
    assert_includes future_updates, status_updates(:scheduled_maintenance)
    assert_not_includes future_updates, status_updates(:completed_maintenance)
  end

  test "active scope should return scheduled and in_progress" do
    active_updates = StatusUpdate.active
    assert_includes active_updates, status_updates(:scheduled_maintenance)
    assert_includes active_updates, status_updates(:in_progress_maintenance)
    assert_not_includes active_updates, status_updates(:completed_maintenance)
  end

  test "should belong to component, user, and account" do
    assert_respond_to @status_update, :component
    assert_respond_to @status_update, :user
    assert_respond_to @status_update, :account

    assert_equal @component, @status_update.component
    assert_equal @user, @status_update.user
    assert_equal @account, @status_update.account
  end
end
