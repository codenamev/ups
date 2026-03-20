require "test_helper"

class Api::V1::UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = accounts(:one)
    @user = users(:one)

    @auth_header = api_auth_header
  end

  # --- Authentication ---

  test "returns 401 without authentication" do
    get api_v1_profile_url

    assert_response :unauthorized
  end

  # --- Show (profile) ---

  test "show returns current user profile" do
    get api_v1_profile_url, headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    assert json.key?("user"), "Expected response to contain 'user' key"
    assert_equal @user.id, json["user"]["id"]
    assert_equal @user.name, json["user"]["name"]
    assert_equal @user.email, json["user"]["email"]
  end

  test "show returns user details" do
    get api_v1_profile_url, headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    user_json = json["user"]
    assert user_json.key?("id")
    assert user_json.key?("name")
    assert user_json.key?("email")
    assert user_json.key?("created_at")
    assert user_json.key?("updated_at")
  end

  test "show returns account information" do
    get api_v1_profile_url, headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    assert json.key?("account"), "Expected response to contain 'account' key"
    account_json = json["account"]
    assert_equal @account.id, account_json["id"]
    assert_equal @account.name, account_json["name"]
    assert_equal @account.slug, account_json["slug"]
    assert account_json.key?("plan")
    assert account_json.key?("status_pages_count")
    assert account_json.key?("components_count")
    assert account_json.key?("monitors_count")
    assert account_json.key?("team_members_count")
  end
end
