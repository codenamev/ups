require "test_helper"

class Api::V1::DiscoveryControllerTest < ActionDispatch::IntegrationTest
  test "show returns API discovery information without authentication" do
    get api_v1_url

    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal "v1", json["api_version"]
    assert_equal "Bearer token", json["authentication"]
  end

  test "show includes enum definitions" do
    get api_v1_url

    json = JSON.parse(response.body)
    assert json.key?("enums"), "Expected response to contain 'enums' key"
    assert_includes json["enums"]["component_status"], "operational"
    assert_includes json["enums"]["incident_status"], "investigating"
    assert_includes json["enums"]["incident_impact"], "minor"
  end

  test "show includes rate limit information" do
    get api_v1_url

    json = JSON.parse(response.body)
    assert_equal 60, json["rate_limit"]["requests_per_minute"]
  end

  test "show includes features list" do
    get api_v1_url

    json = JSON.parse(response.body)
    assert_kind_of Array, json["features"]
    assert_includes json["features"], "idempotency_keys"
    assert_includes json["features"], "webhooks"
    assert_includes json["features"], "structured_errors"
  end

  test "show includes endpoint references" do
    get api_v1_url

    json = JSON.parse(response.body)
    assert json.key?("endpoints"), "Expected response to contain 'endpoints' key"
    assert_equal "/api/v1/status_pages", json["endpoints"]["status_pages"]
  end
end
