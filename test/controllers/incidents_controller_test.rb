require "test_helper"

class IncidentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = accounts(:one)
    @user = users(:one)
    @status_page = status_pages(:one)
    @incident = incidents(:one)
    @component = components(:one)

    # Upgrade to pro to avoid plan limits

    # Sign in via magic link token verification
    token = @user.generate_token_for(:magic_link)
    get verify_magic_link_url(token: token)
  end

  # == Index ==

  test "should get index" do
    get status_page_incidents_url(@status_page)
    assert_response :success
  end

  # == Show ==

  test "should get show" do
    get status_page_incident_url(@status_page, @incident)
    assert_response :success
  end

  # == New ==

  test "should get new" do
    get new_status_page_incident_url(@status_page)
    assert_response :success
  end

  # == Edit ==

  test "should get edit" do
    get edit_status_page_incident_url(@status_page, @incident)
    assert_response :success
  end

  # == Create ==

  test "should create incident with valid params" do
    assert_difference("Incident.count") do
      post status_page_incidents_url(@status_page), params: {
        incident: {
          title: "New Test Incident",
          description: "Something went wrong",
          status: "investigating",
          impact: "minor",
          status_page_id: @status_page.id
        }
      }
    end

    assert_response :redirect
    incident = Incident.last
    assert_equal "New Test Incident", incident.title
    assert_equal "investigating", incident.status
    assert_equal "minor", incident.impact
    assert_equal @user, incident.user
    assert_equal @account, incident.account
  end

  test "should create incident and record incident_created event" do
    assert_difference("IncidentEvent.count") do
      post status_page_incidents_url(@status_page), params: {
        incident: {
          title: "Event Test Incident",
          description: "Testing events",
          status: "investigating",
          impact: "major",
          status_page_id: @status_page.id
        }
      }
    end

    event = IncidentEvent.last
    assert_equal "incident_created", event.event_type
  end

  test "should create incident with components" do
    post status_page_incidents_url(@status_page), params: {
      incident: {
        title: "Incident With Components",
        description: "Testing component attachment",
        status: "investigating",
        impact: "minor",
        status_page_id: @status_page.id
      },
      component_ids: [@component.id]
    }

    assert_response :redirect
    incident = Incident.last
    assert_includes incident.components, @component
  end

  test "should not create incident without title" do
    assert_no_difference("Incident.count") do
      post status_page_incidents_url(@status_page), params: {
        incident: {
          title: "",
          description: "Missing title",
          status: "investigating",
          impact: "minor",
          status_page_id: @status_page.id
        }
      }
    end

    assert_response :unprocessable_entity
  end

  # == Update ==

  test "should update incident" do
    patch status_page_incident_url(@status_page, @incident), params: {
      incident: {
        title: "Updated Incident Title",
        description: "Updated description"
      }
    }

    assert_response :redirect
    @incident.reload
    assert_equal "Updated Incident Title", @incident.title
    assert_equal "Updated description", @incident.description
  end

  test "should update incident status and create event" do
    original_status = @incident.status

    patch status_page_incident_url(@status_page, @incident), params: {
      incident: {
        status: "monitoring"
      }
    }

    assert_response :redirect
    @incident.reload
    assert_equal "monitoring", @incident.status

    event = @incident.incident_events.where(event_type: "status_changed").last
    assert_not_nil event
    assert_equal original_status, event.data["old_status"]
    assert_equal "monitoring", event.data["new_status"]
  end

  test "should update incident with component changes" do
    # First, ensure the incident has no components initially (remove fixture association)
    @incident.incident_components.destroy_all

    # Add a component via update
    patch status_page_incident_url(@status_page, @incident), params: {
      incident: { title: @incident.title },
      component_ids: [@component.id]
    }

    assert_response :redirect
    @incident.reload
    assert_includes @incident.components, @component

    # Verify component_added event was created
    event = @incident.incident_events.where(event_type: "component_added").last
    assert_not_nil event
  end

  test "should not update incident with blank title" do
    original_title = @incident.title

    patch status_page_incident_url(@status_page, @incident), params: {
      incident: {
        title: ""
      }
    }

    assert_response :unprocessable_entity
    @incident.reload
    assert_equal original_title, @incident.title
  end

  # == Destroy ==

  test "should destroy incident" do
    assert_difference("Incident.count", -1) do
      delete status_page_incident_url(@status_page, @incident)
    end

    assert_response :redirect
  end

  # == Authentication ==

  test "should require authentication for index" do
    delete sign_out_url
    get status_page_incidents_url(@status_page)
    assert_response :redirect
    assert_redirected_to new_session_path
  end

  # == Scoping ==

  test "should scope incidents to current account" do
    other_incident = incidents(:two)

    get status_page_incidents_url(@status_page)
    assert_response :success
    assert_includes response.body, @incident.title
    assert_not_includes response.body, other_incident.title
  end
end
