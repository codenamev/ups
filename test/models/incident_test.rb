require "test_helper"

class IncidentTest < ActiveSupport::TestCase
  setup do
    @incident = incidents(:one)
    @account = accounts(:one)
    @status_page = status_pages(:one)
    @user = users(:one)

    # Stub broadcast and notification callbacks to avoid side effects
    @original_notify_created = NotificationService.method(:notify_incident_created)
    @original_notify_resolved = NotificationService.method(:notify_incident_resolved)
    NotificationService.define_singleton_method(:notify_incident_created) { |*| nil }
    NotificationService.define_singleton_method(:notify_incident_resolved) { |*| nil }
  end

  teardown do
    NotificationService.define_singleton_method(:notify_incident_created, @original_notify_created)
    NotificationService.define_singleton_method(:notify_incident_resolved, @original_notify_resolved)
  end

  # --- Validations ---

  test "valid incident" do
    assert @incident.valid?
  end

  test "requires title" do
    @incident.title = nil
    assert_not @incident.valid?
    assert_includes @incident.errors[:title], "can't be blank"
  end

  test "title must be at most 255 characters" do
    @incident.title = "a" * 256
    assert_not @incident.valid?
  end

  test "description must be at most 5000 characters" do
    @incident.description = "a" * 5001
    assert_not @incident.valid?
  end

  test "description can be blank" do
    @incident.description = ""
    assert @incident.valid?
  end

  test "requires status" do
    @incident.status = nil
    assert_not @incident.valid?
    assert_includes @incident.errors[:status], "can't be blank"
  end

  test "requires impact" do
    @incident.impact = nil
    assert_not @incident.valid?
    assert_includes @incident.errors[:impact], "can't be blank"
  end

  test "requires started_at" do
    @incident.started_at = nil
    assert_not @incident.valid?
    assert_includes @incident.errors[:started_at], "can't be blank"
  end

  test "requires resolved_at when status is resolved" do
    @incident.status = :resolved
    @incident.resolved_at = nil
    assert_not @incident.valid?
    assert_includes @incident.errors[:resolved_at], "can't be blank"
  end

  test "does not require resolved_at when status is not resolved" do
    @incident.status = :investigating
    @incident.resolved_at = nil
    assert @incident.valid?
  end

  test "resolved_at must be after started_at" do
    @incident.status = :resolved
    @incident.started_at = Time.current
    @incident.resolved_at = 1.hour.ago
    assert_not @incident.valid?
    assert_includes @incident.errors[:resolved_at], "must be after the incident started"
  end

  # --- Enums ---

  test "status enum values" do
    assert_equal({ "investigating" => 0, "identified" => 1, "monitoring" => 2, "resolved" => 3 },
                 Incident.statuses)
  end

  test "impact enum values" do
    assert_equal({ "minor" => 0, "major" => 1, "critical" => 2, "maintenance" => 3 },
                 Incident.impacts)
  end

  test "status enum prefix methods" do
    @incident.status = :investigating
    assert @incident.status_investigating?
    assert_not @incident.status_resolved?
  end

  test "impact enum prefix methods" do
    @incident.impact = :critical
    assert @incident.impact_critical?
    assert_not @incident.impact_minor?
  end

  # --- Scopes ---

  test "active scope excludes resolved incidents" do
    @incident.update!(status: :investigating, resolved_at: nil)
    resolved = incidents(:two)
    resolved.update!(status: :resolved, resolved_at: Time.current)

    active = Incident.active
    assert_includes active, @incident
    assert_not_includes active, resolved
  end

  test "recent scope returns incidents from last 30 days" do
    recent_incidents = Incident.recent
    assert_includes recent_incidents, @incident
  end

  # --- Callbacks ---

  test "set_started_at sets started_at on create if blank" do
    freeze_time do
      incident = Incident.create!(
        account: @account,
        status_page: @status_page,
        user: @user,
        title: "New Incident",
        status: :investigating,
        impact: :minor
      )
      assert_equal Time.current, incident.started_at
    end
  end

  test "set_started_at does not overwrite existing started_at" do
    custom_time = 2.hours.ago.change(usec: 0)
    incident = Incident.create!(
      account: @account,
      status_page: @status_page,
      user: @user,
      title: "New Incident",
      status: :investigating,
      impact: :minor,
      started_at: custom_time
    )
    assert_equal custom_time, incident.started_at
  end

  test "set_resolved_at sets resolved_at when status changes to resolved" do
    @incident.update!(status: :investigating, resolved_at: nil)
    freeze_time do
      @incident.update!(status: :resolved, resolved_at: Time.current)
      assert_not_nil @incident.resolved_at
    end
  end

  # --- Instance methods ---

  test "name returns title" do
    assert_equal @incident.title, @incident.name
  end

  test "shortlink returns formatted link" do
    expected = "#{@status_page.slug}/incidents/#{@incident.id}"
    assert_equal expected, @incident.shortlink
  end

  # --- Associations ---

  test "belongs to account" do
    assert_equal @account, @incident.account
  end

  test "belongs to status page" do
    assert_equal @status_page, @incident.status_page
  end

  test "belongs to user" do
    assert_equal @user, @incident.user
  end

  test "has many incident updates" do
    assert_respond_to @incident, :incident_updates
  end
end
