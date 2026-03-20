require "test_helper"

class Api::V1::ApiTokensControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = accounts(:one)
    @user = users(:one)
    @api_token = api_tokens(:one)

    @auth_header = api_auth_header
  end

  # --- Authentication ---

  test "returns 401 without authentication" do
    get api_v1_api_tokens_url

    assert_response :unauthorized
  end

  # --- Index ---

  test "index returns api tokens as JSON" do
    get api_v1_api_tokens_url, headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    assert json.key?("api_tokens"), "Expected response to contain 'api_tokens' key"
    assert_kind_of Array, json["api_tokens"]
  end

  test "index returns tokens scoped to current account" do
    get api_v1_api_tokens_url, headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    token_ids = json["api_tokens"].map { |t| t["id"] }
    assert_includes token_ids, @api_token.id
    # Should not include tokens from other accounts
    other_token = api_tokens(:two)
    refute_includes token_ids, other_token.id
  end

  test "index returns token details with user information" do
    get api_v1_api_tokens_url, headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    token_json = json["api_tokens"].first
    assert token_json.key?("id")
    assert token_json.key?("name")
    assert token_json.key?("masked_token")
    assert token_json.key?("user")
    assert token_json["user"].key?("id")
    assert token_json["user"].key?("name")
    assert token_json["user"].key?("email")
  end

  # --- Create ---

  test "create creates a new api token" do
    assert_difference("ApiToken.count") do
      post api_v1_api_tokens_url, headers: @auth_header, params: {
        api_token: { name: "New Token" }
      }
    end

    assert_response :created
    json = JSON.parse(response.body)
    assert_equal "New Token", json["api_token"]["name"]
    assert json["api_token"].key?("token"), "Expected full token to be returned on create"
    assert json["api_token"].key?("masked_token")
  end

  test "create returns validation error without name" do
    assert_no_difference("ApiToken.count") do
      post api_v1_api_tokens_url, headers: @auth_header, params: {
        api_token: { name: "" }
      }
    end

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert json.key?("error")
    assert_equal "validation_failed", json["error"]["code"]
  end

  test "create returns 400 without api_token parameter" do
    post api_v1_api_tokens_url, headers: @auth_header, params: {}

    assert_response :bad_request
    json = JSON.parse(response.body)
    assert json.key?("error")
  end

  # --- Destroy ---

  test "destroy deletes an api token" do
    # Create a token we can delete (not the one we're authenticating with)
    extra_token = @account.api_tokens.create!(
      name: "Deletable Token",
      user: @user,
      token_prefix: "ups_test_del_#{SecureRandom.hex(4)}",
      token_digest: Digest::SHA256.hexdigest("deleteme")
    )

    assert_difference("ApiToken.count", -1) do
      delete api_v1_api_token_url(extra_token), headers: @auth_header
    end

    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal "API token deleted successfully", json["message"]
  end

  test "destroy returns 404 for token from another account" do
    other_token = api_tokens(:two)

    delete api_v1_api_token_url(other_token), headers: @auth_header

    assert_response :not_found
  end

  test "destroy returns 404 for nonexistent token" do
    delete api_v1_api_token_url(id: 999999), headers: @auth_header

    assert_response :not_found
  end
end
