require "test_helper"

class Api::V1::IncidentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = accounts(:one)
    @user = users(:one)
    @status_page = status_pages(:one)
    @incident = incidents(:one)

    @auth_header = { "Authorization" => "Bearer ups_test_one_abcdef1234567890" }
  end

  # --- Authentication ---

  test "returns 401 without authentication" do
    get api_v1_status_page_incidents_url(@status_page)

    assert_response :unauthorized
  end

  # --- Index ---

  test "index returns incidents as JSON" do
    get api_v1_status_page_incidents_url(@status_page), headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    assert json.key?("incidents"), "Expected response to contain 'incidents' key"
    assert_kind_of Array, json["incidents"]
  end

  test "index returns incidents scoped to the status page" do
    get api_v1_status_page_incidents_url(@status_page), headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    incident_ids = json["incidents"].map { |i| i["id"] }
    assert_includes incident_ids, @incident.id
    # Should not include incidents from other status pages
    other_incident = incidents(:two)
    refute_includes incident_ids, other_incident.id
  end

  test "index returns incident details" do
    get api_v1_status_page_incidents_url(@status_page), headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    incident = json["incidents"].first
    assert incident.key?("id")
    assert incident.key?("title")
    assert incident.key?("status")
    assert incident.key?("impact")
    assert incident.key?("started_at")
    assert incident.key?("created_by")
    assert incident.key?("shortlink")
  end

  test "index returns 404 for nonexistent status page" do
    get api_v1_status_page_incidents_url("nonexistent-slug"), headers: @auth_header

    assert_response :not_found
  end

  test "index returns 404 for status page from another account" do
    other_page = status_pages(:two)

    get api_v1_status_page_incidents_url(other_page), headers: @auth_header

    assert_response :not_found
  end

  # --- Show ---

  test "show returns a single incident" do
    get api_v1_status_page_incident_url(@status_page, @incident), headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    assert json.key?("incident")
    assert_equal @incident.id, json["incident"]["id"]
    assert_equal @incident.title, json["incident"]["title"]
  end

  test "show includes updates in the response" do
    get api_v1_status_page_incident_url(@status_page, @incident), headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["incident"].key?("updates")
    assert_kind_of Array, json["incident"]["updates"]
  end

  test "show returns 404 for nonexistent incident" do
    get api_v1_status_page_incident_url(@status_page, id: 999999), headers: @auth_header

    assert_response :not_found
  end

  test "show returns 404 for incident on another accounts status page" do
    other_page = status_pages(:two)
    other_incident = incidents(:two)

    get api_v1_status_page_incident_url(other_page, other_incident), headers: @auth_header

    assert_response :not_found
  end

  # --- Create ---

  test "create creates a new incident" do
    assert_difference("Incident.count") do
      post api_v1_status_page_incidents_url(@status_page), headers: @auth_header, params: {
        incident: {
          title: "New Outage",
          description: "Something broke",
          status: "investigating",
          impact: "major"
        }
      }
    end

    assert_response :created
    json = JSON.parse(response.body)
    assert_equal "New Outage", json["incident"]["title"]
    assert_equal "investigating", json["incident"]["status"]
    assert_equal "major", json["incident"]["impact"]
  end

  test "create returns validation error without title" do
    assert_no_difference("Incident.count") do
      post api_v1_status_page_incidents_url(@status_page), headers: @auth_header, params: {
        incident: {
          title: "",
          status: "investigating",
          impact: "minor"
        }
      }
    end

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert_equal "validation_failed", json["error"]["code"]
  end

  test "create returns 400 without incident parameter" do
    post api_v1_status_page_incidents_url(@status_page), headers: @auth_header, params: {}

    assert_response :bad_request
  end

  # --- Update ---

  test "update changes an incident" do
    patch api_v1_status_page_incident_url(@status_page, @incident), headers: @auth_header, params: {
      incident: { title: "Updated Title" }
    }

    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal "Updated Title", json["incident"]["title"]
  end

  test "update can change incident status" do
    patch api_v1_status_page_incident_url(@status_page, @incident), headers: @auth_header, params: {
      incident: { status: "monitoring" }
    }

    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal "monitoring", json["incident"]["status"]
  end

  test "update returns validation error with blank title" do
    patch api_v1_status_page_incident_url(@status_page, @incident), headers: @auth_header, params: {
      incident: { title: "" }
    }

    assert_response :unprocessable_entity
  end

  test "update returns 404 for incident from another account" do
    other_page = status_pages(:two)
    other_incident = incidents(:two)

    patch api_v1_status_page_incident_url(other_page, other_incident), headers: @auth_header, params: {
      incident: { title: "Hacked" }
    }

    assert_response :not_found
  end

  # --- Destroy ---

  test "destroy deletes an incident" do
    incident = @status_page.incidents.create!(
      title: "Deletable Incident",
      status: :investigating,
      impact: :minor,
      account: @account,
      user: @user,
      started_at: Time.current
    )

    assert_difference("Incident.count", -1) do
      delete api_v1_status_page_incident_url(@status_page, incident), headers: @auth_header
    end

    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal "Incident deleted successfully", json["message"]
  end

  test "destroy returns 404 for incident from another account" do
    other_page = status_pages(:two)
    other_incident = incidents(:two)

    delete api_v1_status_page_incident_url(other_page, other_incident), headers: @auth_header

    assert_response :not_found
  end

  test "destroy returns 404 for nonexistent incident" do
    delete api_v1_status_page_incident_url(@status_page, id: 999999), headers: @auth_header

    assert_response :not_found
  end
end
