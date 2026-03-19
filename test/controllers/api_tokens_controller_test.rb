require "test_helper"

class ApiTokensControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = accounts(:one)
    @user = users(:one)
    @api_token = api_tokens(:one)
    sign_in_as(@user)
  end

  test "should get index" do
    get api_tokens_url
    assert_response :success
  end

  test "should get new" do
    get new_api_token_url
    assert_response :success
  end

  test "should create api token" do
    assert_difference("ApiToken.count") do
      post api_tokens_url, params: {
        api_token: { name: "My New Token" }
      }
    end

    token = ApiToken.last
    assert_equal "My New Token", token.name
    assert_equal @account, token.account
    assert_equal @user, token.user
    assert_redirected_to api_tokens_url
  end

  test "should return full token in flash after creation" do
    post api_tokens_url, params: {
      api_token: { name: "Flash Token" }
    }

    assert_redirected_to api_tokens_url
    assert flash[:api_token].present?, "Expected flash[:api_token] to be set"
    assert_equal "Flash Token", flash[:api_token][:name]
    assert_match(/\Aups_test_\h+_\h+\z/, flash[:api_token][:token])
  end

  test "should not create api token without name" do
    assert_no_difference("ApiToken.count") do
      post api_tokens_url, params: {
        api_token: { name: "" }
      }
    end

    assert_response :unprocessable_entity
  end

  test "should destroy api token" do
    assert_difference("ApiToken.count", -1) do
      delete api_token_url(@api_token)
    end

    assert_redirected_to api_tokens_url
  end
end
