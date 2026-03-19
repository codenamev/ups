require "test_helper"

class UnsubscribeControllerTest < ActionDispatch::IntegrationTest
  setup do
    @subscriber = subscribers(:one)
  end

  test "should show unsubscribe page with valid token" do
    get unsubscribe_path(token: @subscriber.unsubscribe_token)
    assert_response :success
    assert_includes response.body, "Unsubscribe from Notifications"
  end

  test "should show invalid token page with invalid token" do
    get unsubscribe_path(token: "invalid-token")
    assert_response :success
    assert_includes response.body, "Invalid unsubscribe link"
  end

  test "should unsubscribe with valid token" do
    assert_nil @subscriber.unsubscribed_at

    post unsubscribe_confirm_path(token: @subscriber.unsubscribe_token)

    assert_response :success
    @subscriber.reload
    assert_not_nil @subscriber.unsubscribed_at
  end

  test "should show invalid token when confirming with invalid token" do
    post unsubscribe_confirm_path(token: "invalid-token")
    assert_response :success
    assert_includes response.body, "Invalid unsubscribe link"
  end
end
