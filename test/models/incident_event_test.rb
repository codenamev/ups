require "test_helper"

class IncidentEventTest < ActiveSupport::TestCase
  setup do
    @event = incident_events(:one)
    @incident = incidents(:one)
    @user = users(:one)
  end

  # --- Associations ---

  test "belongs to incident" do
    assert_equal @incident, @event.incident
  end

  test "belongs to user" do
    assert_equal @user, @event.user
  end

  # --- TYPES constant ---

  test "TYPES contains expected event types" do
    expected = %w[
      incident_created
      status_changed
      component_added
      component_removed
      update_posted
      update_edited
      incident_resolved
      reopened
    ]
    assert_equal expected, IncidentEvent::TYPES
  end

  test "TYPES is frozen" do
    assert_predicate IncidentEvent::TYPES, :frozen?
  end

  # --- Validations ---

  test "valid with all required attributes" do
    event = IncidentEvent.new(
      incident: @incident,
      user: @user,
      event_type: "incident_created",
      data: { title: "Test" }
    )
    assert event.valid?
  end

  test "invalid without event_type" do
    event = IncidentEvent.new(
      incident: @incident,
      user: @user,
      occurred_at: Time.current
    )
    assert_not event.valid?
    assert_includes event.errors[:event_type], "can't be blank"
  end

  test "invalid with unrecognized event_type" do
    event = IncidentEvent.new(
      incident: @incident,
      user: @user,
      event_type: "bogus_type",
      occurred_at: Time.current
    )
    assert_not event.valid?
    assert event.errors[:event_type].any? { |e| e.include?("is not included") }
  end

  test "each TYPES value is accepted" do
    IncidentEvent::TYPES.each do |type|
      event = IncidentEvent.new(
        incident: @incident,
        user: @user,
        event_type: type,
        data: {}
      )
      event.valid?
      assert_not event.errors[:event_type].any?, "Expected #{type} to be valid"
    end
  end

  # --- Callback: set_occurred_at ---

  test "set_occurred_at fills in occurred_at on create when blank" do
    freeze_time do
      event = IncidentEvent.new(
        incident: @incident,
        user: @user,
        event_type: "incident_created",
        data: { title: "Test" }
      )
      event.valid?
      assert_equal Time.current, event.occurred_at
    end
  end

  test "set_occurred_at does not overwrite existing occurred_at" do
    custom_time = 3.days.ago.change(usec: 0)
    event = IncidentEvent.new(
      incident: @incident,
      user: @user,
      event_type: "incident_created",
      occurred_at: custom_time,
      data: {}
    )
    event.valid?
    assert_equal custom_time, event.occurred_at
  end

  # --- Serialization ---

  test "data field is serialized as JSON" do
    @event.data = { "key" => "value", "nested" => { "a" => 1 } }
    @event.save!
    @event.reload
    assert_equal({ "key" => "value", "nested" => { "a" => 1 } }, @event.data)
  end

  # --- Scopes ---

  test "chronological orders by occurred_at and id" do
    earlier = @event
    later = incident_events(:two)
    earlier.update_columns(occurred_at: 2.hours.ago)
    later.update_columns(occurred_at: 1.hour.ago)

    result = IncidentEvent.chronological
    earlier_idx = result.index(earlier)
    later_idx = result.index(later)
    assert earlier_idx < later_idx, "earlier event should come first"
  end

  test "for_incident returns only events for given incident" do
    events = IncidentEvent.for_incident(@incident.id)
    events.each do |event|
      assert_equal @incident.id, event.incident_id
    end
  end

  test "for_incident excludes events for other incidents" do
    other_incident = incidents(:two)
    events = IncidentEvent.for_incident(@incident.id)
    events.each do |event|
      assert_not_equal other_incident.id, event.incident_id
    end
  end

  # --- Class methods ---

  test "initial_state returns default state hash" do
    state = IncidentEvent.send(:initial_state)
    assert_equal "investigating", state[:status]
    assert_equal "minor", state[:impact]
    assert_equal [], state[:component_ids]
    assert_equal 0, state[:updates_count]
  end

  test "apply_event handles incident_created" do
    state = IncidentEvent.send(:initial_state)
    event = IncidentEvent.new(
      event_type: "incident_created",
      data: { "status" => "identified", "impact" => "major" }
    )
    result = IncidentEvent.apply_event(state, event)
    assert_equal "identified", result[:status]
    assert_equal "major", result[:impact]
  end

  test "apply_event handles status_changed" do
    state = IncidentEvent.send(:initial_state)
    event = IncidentEvent.new(
      event_type: "status_changed",
      data: { "new_status" => "monitoring" }
    )
    result = IncidentEvent.apply_event(state, event)
    assert_equal "monitoring", result[:status]
  end

  test "apply_event handles component_added" do
    state = IncidentEvent.send(:initial_state)
    event = IncidentEvent.new(
      event_type: "component_added",
      data: { "component_id" => 42 }
    )
    result = IncidentEvent.apply_event(state, event)
    assert_includes result[:component_ids], 42
  end

  test "apply_event handles update_posted" do
    state = IncidentEvent.send(:initial_state)
    event = IncidentEvent.new(
      event_type: "update_posted",
      data: {}
    )
    result = IncidentEvent.apply_event(state, event)
    assert_equal 1, result[:updates_count]
  end

  test "apply_event returns state unchanged for unknown event type" do
    state = IncidentEvent.send(:initial_state).dup
    event = IncidentEvent.new(
      event_type: "reopened",
      data: {}
    )
    result = IncidentEvent.apply_event(state, event)
    assert_equal state, result
  end

  test "rebuild_incident_state replays all events for an incident" do
    # The fixture :one has an incident_created event
    state = IncidentEvent.rebuild_incident_state(@incident.id)
    assert state.is_a?(Hash)
    assert state.key?(:status)
    assert state.key?(:component_ids)
    assert state.key?(:updates_count)
  end
end
