require "test_helper"

class Api::V1::StatusPagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = accounts(:one)
    @user = users(:one)
    @status_page = status_pages(:one)

    @auth_header = api_auth_header
  end

  # --- Authentication ---

  test "returns 401 without authentication" do
    get api_v1_status_pages_url

    assert_response :unauthorized
  end

  # --- Index ---

  test "index returns status pages as JSON" do
    get api_v1_status_pages_url, headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    assert json.key?("status_pages"), "Expected response to contain 'status_pages' key"
    assert_kind_of Array, json["status_pages"]
  end

  test "index returns status pages scoped to current account" do
    get api_v1_status_pages_url, headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    page_ids = json["status_pages"].map { |p| p["id"] }
    assert_includes page_ids, @status_page.id
    # Should not include pages from other accounts
    other_page = status_pages(:two)
    refute_includes page_ids, other_page.id
  end

  test "index returns status page details" do
    get api_v1_status_pages_url, headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    page = json["status_pages"].first
    assert page.key?("id")
    assert page.key?("name")
    assert page.key?("slug")
    assert page.key?("description")
    assert page.key?("url")
    assert page.key?("overall_status")
    assert page.key?("components_count")
    assert page.key?("incidents_count")
  end

  # --- Show ---

  test "show returns a single status page by id" do
    get api_v1_status_page_url(@status_page), headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    assert json.key?("status_page")
    assert_equal @status_page.id, json["status_page"]["id"]
    assert_equal @status_page.name, json["status_page"]["name"]
  end

  test "show returns a status page by slug" do
    get api_v1_status_page_url(@status_page.slug), headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    assert json.key?("status_page")
    assert_equal @status_page.slug, json["status_page"]["slug"]
  end

  test "show includes components and recent incidents" do
    get api_v1_status_page_url(@status_page), headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["status_page"].key?("components")
    assert json["status_page"].key?("recent_incidents")
  end

  test "show returns 404 for nonexistent status page" do
    get api_v1_status_page_url("nonexistent-slug"), headers: @auth_header

    assert_response :not_found
  end

  test "show returns 404 for status page from another account" do
    other_page = status_pages(:two)

    get api_v1_status_page_url(other_page), headers: @auth_header

    assert_response :not_found
  end

  # --- Create ---

  test "create creates a new status page" do
    assert_difference("StatusPage.count") do
      post api_v1_status_pages_url, headers: @auth_header, params: {
        status_page: { name: "New Status Page", description: "A new page" }
      }
    end

    assert_response :created
    json = JSON.parse(response.body)
    assert_equal "New Status Page", json["status_page"]["name"]
    assert json["status_page"].key?("slug")
  end

  test "create returns validation error without name" do
    assert_no_difference("StatusPage.count") do
      post api_v1_status_pages_url, headers: @auth_header, params: {
        status_page: { name: "", description: "Missing name" }
      }
    end

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert_equal "validation_failed", json["error"]["code"]
  end

  test "create returns 400 without status_page parameter" do
    post api_v1_status_pages_url, headers: @auth_header, params: {}

    assert_response :bad_request
  end

  # --- Update ---

  test "update changes a status page" do
    patch api_v1_status_page_url(@status_page), headers: @auth_header, params: {
      status_page: { name: "Updated Name" }
    }

    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal "Updated Name", json["status_page"]["name"]
  end

  test "update returns validation error with blank name" do
    patch api_v1_status_page_url(@status_page), headers: @auth_header, params: {
      status_page: { name: "" }
    }

    assert_response :unprocessable_entity
  end

  test "update returns 404 for status page from another account" do
    other_page = status_pages(:two)

    patch api_v1_status_page_url(other_page), headers: @auth_header, params: {
      status_page: { name: "Hacked" }
    }

    assert_response :not_found
  end

  # --- Destroy ---

  test "destroy deletes a status page" do
    page = @account.status_pages.create!(name: "Deletable Page")

    assert_difference("StatusPage.count", -1) do
      delete api_v1_status_page_url(page), headers: @auth_header
    end

    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal "Status page deleted successfully", json["message"]
  end

  test "destroy returns 404 for status page from another account" do
    other_page = status_pages(:two)

    delete api_v1_status_page_url(other_page), headers: @auth_header

    assert_response :not_found
  end

  test "destroy returns 404 for nonexistent status page" do
    delete api_v1_status_page_url(id: 999999), headers: @auth_header

    assert_response :not_found
  end
end
