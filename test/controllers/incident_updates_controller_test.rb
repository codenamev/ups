require "test_helper"

class IncidentUpdatesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = accounts(:one)
    @user = users(:one)
    @status_page = status_pages(:one)
    @incident = incidents(:one)
    @incident_update = incident_updates(:one)

    # Upgrade to pro to avoid plan limits

    # Sign in via magic link token verification
    token = @user.generate_token_for(:magic_link)
    get verify_magic_link_url(token: token)
  end

  # == New ==

  test "should get new" do
    get new_status_page_incident_incident_update_url(@status_page, @incident)
    assert_response :success
  end

  # == Create ==

  test "should create incident update" do
    assert_difference("IncidentUpdate.count") do
      post status_page_incident_incident_updates_url(@status_page, @incident), params: {
        incident_update: {
          title: "Update on the issue",
          content: "We have identified the root cause.",
          status: @incident.status
        }
      }
    end

    assert_response :redirect
    update = IncidentUpdate.last
    assert_equal "Update on the issue", update.title
    assert_equal "We have identified the root cause.", update.content
    assert_equal @user, update.user
  end

  test "should create incident update and change incident status" do
    # Ensure the incident starts with a different status
    @incident.update!(status: "investigating")

    assert_difference("IncidentUpdate.count") do
      post status_page_incident_incident_updates_url(@status_page, @incident), params: {
        incident_update: {
          title: "Status update",
          content: "We are now monitoring the fix.",
          status: "monitoring"
        }
      }
    end

    assert_response :redirect
    @incident.reload
    assert_equal "monitoring", @incident.status

    # Verify status_changed event was created
    event = @incident.incident_events.where(event_type: "status_changed").last
    assert_not_nil event
    assert_equal "investigating", event.data["old_status"]
    assert_equal "monitoring", event.data["new_status"]
  end

  test "should create incident update and record update_posted event" do
    # Use the same status as the incident to avoid a status_changed event
    post status_page_incident_incident_updates_url(@status_page, @incident), params: {
      incident_update: {
        title: "Event tracking test",
        content: "Testing event creation.",
        status: @incident.status
      }
    }

    assert_response :redirect
    event = @incident.incident_events.where(event_type: "update_posted").last
    assert_not_nil event
  end

  test "should not create incident update without title" do
    assert_no_difference("IncidentUpdate.count") do
      post status_page_incident_incident_updates_url(@status_page, @incident), params: {
        incident_update: {
          title: "",
          content: "Missing title.",
          status: "investigating"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "should not create incident update without content" do
    assert_no_difference("IncidentUpdate.count") do
      post status_page_incident_incident_updates_url(@status_page, @incident), params: {
        incident_update: {
          title: "No content",
          content: "",
          status: "investigating"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  # == Edit ==

  test "should get edit" do
    get edit_status_page_incident_incident_update_url(@status_page, @incident, @incident_update)
    assert_response :success
  end

  # == Update ==

  test "should update incident update" do
    patch status_page_incident_incident_update_url(@status_page, @incident, @incident_update), params: {
      incident_update: {
        title: "Edited update title",
        content: "Edited content for the update."
      }
    }

    assert_response :redirect
    @incident_update.reload
    assert_equal "Edited update title", @incident_update.title
    assert_equal "Edited content for the update.", @incident_update.content
  end

  # == Destroy ==

  test "should destroy incident update" do
    assert_difference("IncidentUpdate.count", -1) do
      delete status_page_incident_incident_update_url(@status_page, @incident, @incident_update)
    end

    assert_response :redirect
  end

  # == Authentication ==

  test "should require authentication" do
    delete sign_out_url
    get new_status_page_incident_incident_update_url(@status_page, @incident)
    assert_response :redirect
    assert_redirected_to new_session_path
  end
end
