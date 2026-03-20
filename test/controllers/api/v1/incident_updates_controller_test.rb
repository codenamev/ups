require "test_helper"

class Api::V1::IncidentUpdatesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = accounts(:one)
    @user = users(:one)
    @status_page = status_pages(:one)
    @incident = incidents(:one)
    @incident_update = incident_updates(:one)

    @auth_header = { "Authorization" => "Bearer ups_test_one_abcdef1234567890" }
  end

  # --- Authentication ---

  test "returns 401 without authentication" do
    get api_v1_status_page_incident_updates_url(@status_page, @incident)

    assert_response :unauthorized
  end

  # --- Index ---

  test "index returns incident updates as JSON" do
    get api_v1_status_page_incident_updates_url(@status_page, @incident), headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    assert json.key?("incident_updates"), "Expected response to contain 'incident_updates' key"
    assert_kind_of Array, json["incident_updates"]
  end

  test "index returns updates scoped to the incident" do
    get api_v1_status_page_incident_updates_url(@status_page, @incident), headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    update_ids = json["incident_updates"].map { |u| u["id"] }
    assert_includes update_ids, @incident_update.id
    # Should not include updates from other incidents
    other_update = incident_updates(:two)
    refute_includes update_ids, other_update.id
  end

  test "index returns update details" do
    get api_v1_status_page_incident_updates_url(@status_page, @incident), headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    update_json = json["incident_updates"].first
    assert update_json.key?("id")
    assert update_json.key?("title")
    assert update_json.key?("content")
    assert update_json.key?("status")
    assert update_json.key?("incident")
    assert update_json.key?("created_by")
  end

  test "index returns 404 for nonexistent status page" do
    get api_v1_status_page_incident_updates_url("nonexistent-slug", @incident), headers: @auth_header

    assert_response :not_found
  end

  test "index returns 404 for status page from another account" do
    other_page = status_pages(:two)
    other_incident = incidents(:two)

    get api_v1_status_page_incident_updates_url(other_page, other_incident), headers: @auth_header

    assert_response :not_found
  end

  # --- Show ---

  test "show returns a single incident update" do
    get api_v1_status_page_incident_update_url(@status_page, @incident, @incident_update), headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    assert json.key?("incident_update")
    assert_equal @incident_update.id, json["incident_update"]["id"]
  end

  test "show returns 404 for nonexistent update" do
    get api_v1_status_page_incident_update_url(@status_page, @incident, id: 999999), headers: @auth_header

    assert_response :not_found
  end

  # --- Create ---

  test "create creates a new incident update" do
    assert_difference("IncidentUpdate.count") do
      post api_v1_status_page_incident_updates_url(@status_page, @incident), headers: @auth_header, params: {
        incident_update: { title: "New Update", content: "We are looking into it", status: "investigating" }
      }
    end

    assert_response :created
    json = JSON.parse(response.body)
    assert_equal "New Update", json["incident_update"]["title"]
    assert_equal "We are looking into it", json["incident_update"]["content"]
  end

  test "create returns validation error without required fields" do
    assert_no_difference("IncidentUpdate.count") do
      post api_v1_status_page_incident_updates_url(@status_page, @incident), headers: @auth_header, params: {
        incident_update: { title: "", content: "" }
      }
    end

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert_equal "validation_failed", json["error"]["code"]
  end

  test "create returns 400 without incident_update parameter" do
    post api_v1_status_page_incident_updates_url(@status_page, @incident), headers: @auth_header, params: {}

    assert_response :bad_request
  end

  test "create can update incident status via incident_status param" do
    post api_v1_status_page_incident_updates_url(@status_page, @incident), headers: @auth_header, params: {
      incident_update: { title: "Fix deployed", content: "Monitoring the fix", status: "monitoring", incident_status: "monitoring" }
    }

    assert_response :created
    @incident.reload
    assert_equal "monitoring", @incident.status
  end

  # --- Update ---

  test "update changes an incident update" do
    patch api_v1_status_page_incident_update_url(@status_page, @incident, @incident_update), headers: @auth_header, params: {
      incident_update: { content: "Updated content" }
    }

    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal "Updated content", json["incident_update"]["content"]
  end

  test "update returns validation error with blank required fields" do
    patch api_v1_status_page_incident_update_url(@status_page, @incident, @incident_update), headers: @auth_header, params: {
      incident_update: { title: "", content: "" }
    }

    assert_response :unprocessable_entity
  end

  test "update returns 404 for update from another account" do
    other_page = status_pages(:two)
    other_incident = incidents(:two)
    other_update = incident_updates(:two)

    patch api_v1_status_page_incident_update_url(other_page, other_incident, other_update), headers: @auth_header, params: {
      incident_update: { content: "Hacked" }
    }

    assert_response :not_found
  end

  # --- Destroy ---

  test "destroy deletes an incident update" do
    update_to_delete = @incident.incident_updates.create!(
      title: "Deletable Update",
      content: "This will be deleted",
      status: :investigating,
      user: @user
    )

    assert_difference("IncidentUpdate.count", -1) do
      delete api_v1_status_page_incident_update_url(@status_page, @incident, update_to_delete), headers: @auth_header
    end

    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal "Incident update deleted successfully", json["message"]
  end

  test "destroy returns 404 for nonexistent update" do
    delete api_v1_status_page_incident_update_url(@status_page, @incident, id: 999999), headers: @auth_header

    assert_response :not_found
  end
end
