require "test_helper"

class Api::V1::ComponentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = accounts(:one)
    @user = users(:one)
    @status_page = status_pages(:one)
    @component = components(:one)

    # Matches fixture api_tokens(:one) which has token_prefix "ups_test_one"
    # and token_digest = SHA256("abcdef1234567890")
    @auth_header = api_auth_header
  end

  test "index returns components as JSON" do
    get api_v1_status_page_components_url(@status_page), headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    assert json.key?("components"), "Expected response to contain 'components' key"
    assert_kind_of Array, json["components"]
  end

  test "index returns components when status_page is looked up by slug" do
    get api_v1_status_page_components_url(@status_page.slug), headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    assert json.key?("components")
  end

  test "show returns a single component" do
    get api_v1_status_page_component_url(@status_page, @component), headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    assert json.key?("component")
    assert_equal @component.id, json["component"]["id"]
  end

  test "create creates a new component" do
    assert_difference("Component.count") do
      post api_v1_status_page_components_url(@status_page), headers: @auth_header, params: {
        component: { name: "New Agent", component_type: "agent" }
      }
    end

    assert_response :created
    json = JSON.parse(response.body)
    assert_equal "New Agent", json["component"]["name"]
  end

  test "update changes component status" do
    patch api_v1_status_page_component_url(@status_page, @component), headers: @auth_header, params: {
      component: { status: "degraded_performance" }
    }

    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal "degraded_performance", json["component"]["status"]
  end

  test "returns 404 for nonexistent status page slug" do
    get api_v1_status_page_components_url("nonexistent-slug"), headers: @auth_header

    assert_response :not_found
  end

  test "returns 401 without authentication" do
    get api_v1_status_page_components_url(@status_page)

    assert_response :unauthorized
  end
end
