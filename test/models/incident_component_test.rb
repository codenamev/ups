require "test_helper"

class IncidentComponentTest < ActiveSupport::TestCase
  setup do
    @incident_component = incident_components(:one)
  end

  # -- Associations --

  test "belongs to incident" do
    assert_respond_to @incident_component, :incident
    assert_instance_of Incident, @incident_component.incident
  end

  test "belongs to component" do
    assert_respond_to @incident_component, :component
    assert_instance_of Component, @incident_component.component
  end

  # -- Fixture sanity --

  test "fixtures are valid" do
    assert incident_components(:one).valid?
    assert incident_components(:two).valid?
  end

  # -- Join model behavior --

  test "links an incident to a component" do
    assert_equal incidents(:one), @incident_component.incident
    assert_equal components(:one), @incident_component.component
  end

  test "can be destroyed without affecting incident or component" do
    incident = @incident_component.incident
    component = @incident_component.component

    @incident_component.destroy

    assert incident.reload
    assert component.reload
  end
end
