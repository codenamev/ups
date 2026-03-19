require "test_helper"

class IncidentWorkflowTest < ActiveSupport::TestCase
  setup do
    @account = accounts(:one)
    @status_page = status_pages(:one)
    @user = users(:one)

    @component1 = Component.create!(
      name: "Component A",
      status: "operational",
      visible: true,
      status_page: @status_page,
      account: @account
    )

    @component2 = Component.create!(
      name: "Component B",
      status: "operational",
      visible: true,
      status_page: @status_page,
      account: @account
    )

    @incident = @status_page.incidents.build(account: @account)

    Current.user = @user
  end

  test "create_with_components creates incident with all related records" do
    workflow = IncidentWorkflow.new(@incident, current_user: @user)

    assert_difference "Incident.count", 1 do
      assert_difference "IncidentEvent.count", 4 do # created, 2x component_added, update_posted
        assert_difference "IncidentUpdate.count", 1 do
          result = workflow.create_with_components(
            title: "API Issues",
            impact: :major,
            component_ids: [ @component1.id, @component2.id ],
            initial_message: "Investigating API slowness"
          )

          assert result.persisted?
          assert_equal "API Issues", result.title
          assert_equal "major", result.impact
          assert_equal "investigating", result.status
          assert_not_nil result.started_at
          assert_equal [ @component1, @component2 ], result.components.sort_by(&:id)
          assert_equal 1, result.incident_updates.count
          assert_equal "Investigating API slowness", result.incident_updates.first.content
        end
      end
    end
  end

  test "create_with_components updates component statuses based on impact" do
    workflow = IncidentWorkflow.new(@incident, current_user: @user)

    assert_equal "operational", @component1.status
    assert_equal "operational", @component2.status

    workflow.create_with_components(
      title: "Critical Issue",
      impact: :critical,
      component_ids: [ @component1.id ],
      initial_message: "Service is down"
    )

    @component1.reload
    assert_equal "major_outage", @component1.status

    # Component2 should remain operational since it wasn't affected
    @component2.reload
    assert_equal "operational", @component2.status
  end

  test "create_with_components records proper events" do
    workflow = IncidentWorkflow.new(@incident, current_user: @user)

    result = workflow.create_with_components(
      title: "Database Issues",
      impact: :minor,
      component_ids: [ @component1.id ],
      initial_message: "Slow queries detected"
    )

    events = result.incident_events.order(:occurred_at)

    # Check incident_created event
    created_event = events.find { |e| e.event_type == "incident_created" }
    assert_not_nil created_event
    assert_equal "Database Issues", created_event.data["title"]

    # Check component_added event
    component_event = events.find { |e| e.event_type == "component_added" }
    assert_not_nil component_event
    assert_equal @component1.id, component_event.data["component_id"]

    # Check update_posted event
    update_event = events.find { |e| e.event_type == "update_posted" }
    assert_not_nil update_event
    assert_equal "Slow queries detected", update_event.data["message"]
    assert_equal "investigating", update_event.data["status"]
  end

  test "transition_to changes incident status with proper validation" do
    incident = create_incident_via_workflow
    workflow = IncidentWorkflow.new(incident, current_user: @user)

    # Valid transition: investigating -> identified
    assert workflow.transition_to(:identified, message: "Root cause found")
    incident.reload
    assert_equal "identified", incident.status

    # Check event was recorded
    transition_event = incident.incident_events.find_by(event_type: "status_changed")
    assert_not_nil transition_event
    assert_equal "investigating", transition_event.data["old_status"]
    assert_equal "identified", transition_event.data["new_status"]

    # Check update was created
    assert_equal 2, incident.incident_updates.count
    latest_update = incident.incident_updates.order(:created_at).last
    assert_equal "Root cause found", latest_update.content
    assert_equal "identified", latest_update.status
  end

  test "transition_to validates state transitions" do
    incident = create_incident_via_workflow
    workflow = IncidentWorkflow.new(incident, current_user: @user)

    # Valid transitions from investigating
    assert workflow.transition_to(:identified)
    incident.reload

    # Invalid transition from identified back to investigating
    assert_not workflow.transition_to(:investigating)
    incident.reload
    assert_equal "identified", incident.status

    # Valid transition from identified to resolved
    assert workflow.transition_to(:resolved, message: "Issue fixed")
    incident.reload
    assert_equal "resolved", incident.status
    assert_not_nil incident.resolved_at
  end

  test "add_component adds component and records event" do
    incident = create_incident_via_workflow
    workflow = IncidentWorkflow.new(incident, current_user: @user)

    assert_not_includes incident.components, @component2

    assert workflow.add_component(@component2.id)
    incident.reload

    assert_includes incident.components, @component2

    # Check event was recorded
    component_events = incident.incident_events.where(event_type: "component_added")
    added_event = component_events.detect { |e| e.data["component_id"] == @component2.id }
    assert_not_nil added_event, "Expected component_added event for component #{@component2.id}"

    # Check component status was updated (since incident is active)
    @component2.reload
    assert_equal "degraded_performance", @component2.status # minor impact -> degraded_performance
  end

  test "remove_component removes component and resets status" do
    incident = create_incident_via_workflow(component_ids: [ @component1.id, @component2.id ])
    workflow = IncidentWorkflow.new(incident, current_user: @user)

    assert_includes incident.components, @component1
    assert_equal "degraded_performance", @component1.reload.status

    assert workflow.remove_component(@component1.id)
    incident.reload

    assert_not_includes incident.components, @component1

    # Check event was recorded
    removed_events = incident.incident_events.where(event_type: "component_removed")
    removed_event = removed_events.detect { |e| e.data["component_id"] == @component1.id }
    assert_not_nil removed_event, "Expected component_removed event for component #{@component1.id}"

    # Component status should reset to operational since no other incidents affect it
    @component1.reload
    assert_equal "operational", @component1.status
  end

  test "calculate_mttr returns correct duration for resolved incidents" do
    incident = create_incident_via_workflow
    workflow = IncidentWorkflow.new(incident, current_user: @user)

    # Simulate incident that lasted 30 minutes
    incident.update!(started_at: 30.minutes.ago)
    workflow.transition_to(:resolved)
    incident.reload

    mttr = workflow.calculate_mttr
    assert_in_delta 30.0, mttr, 1.0 # Within 1 minute tolerance
  end

  private

  def create_incident_via_workflow(component_ids: [ @component1.id ])
    workflow = IncidentWorkflow.new(@status_page.incidents.build(account: @account), current_user: @user)
    workflow.create_with_components(
      title: "Test Incident",
      impact: :minor,
      component_ids: component_ids,
      initial_message: "Test message"
    )
  end
end
