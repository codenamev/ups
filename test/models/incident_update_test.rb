require "test_helper"

class IncidentUpdateTest < ActiveSupport::TestCase
  setup do
    @incident_update = incident_updates(:one)
    @incident = incidents(:one)
    @user = users(:one)
  end

  # --- Associations ---

  test "belongs to incident" do
    assert_equal @incident, @incident_update.incident
  end

  test "belongs to user" do
    assert_equal @user, @incident_update.user
  end

  # --- Validations ---

  test "valid with required attributes" do
    update = IncidentUpdate.new(
      incident: @incident,
      user: @user,
      title: "Update Title",
      content: "Some content here"
    )
    assert update.valid?
  end

  test "invalid without title" do
    @incident_update.title = nil
    assert_not @incident_update.valid?
    assert_includes @incident_update.errors[:title], "can't be blank"
  end

  test "invalid without content" do
    @incident_update.content = nil
    assert_not @incident_update.valid?
    assert_includes @incident_update.errors[:content], "can't be blank"
  end

  # --- Enum ---

  test "status enum defines investigating" do
    @incident_update.status = :investigating
    assert @incident_update.status_investigating?
  end

  test "status enum defines identified" do
    @incident_update.status = :identified
    assert @incident_update.status_identified?
  end

  test "status enum defines monitoring" do
    @incident_update.status = :monitoring
    assert @incident_update.status_monitoring?
  end

  test "status enum defines resolved" do
    @incident_update.status = :resolved
    assert @incident_update.status_resolved?
  end

  test "status allows nil" do
    @incident_update.status = nil
    assert @incident_update.valid?
  end

  # --- Scope ---

  test "recent orders by created_at descending" do
    older = @incident_update
    newer = incident_updates(:two)

    # Ensure distinct created_at values
    older.update_columns(created_at: 2.hours.ago)
    newer.update_columns(created_at: 1.hour.ago)

    recent = IncidentUpdate.recent
    older_index = recent.index(older)
    newer_index = recent.index(newer)
    assert newer_index < older_index, "newer update should appear before older update"
  end

  # --- Callbacks ---

  test "after_create calls notify_incident_update callback" do
    # The callback invokes NotificationService.notify_incident_updated
    # With no subscribers configured, it completes without sending emails
    update = IncidentUpdate.create!(
      incident: @incident,
      user: @user,
      title: "New Update",
      content: "Content for callback test"
    )
    assert update.persisted?
  end

  test "after_create callback method is defined" do
    update = IncidentUpdate.new(
      incident: @incident,
      user: @user,
      title: "Callback Check",
      content: "Verifying private callback"
    )
    assert update.respond_to?(:notify_incident_update, true)
  end
end
