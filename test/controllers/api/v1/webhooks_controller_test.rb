require "test_helper"

class Api::V1::WebhooksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = accounts(:one)
    @status_page = status_pages(:one)
    @webhook = webhooks(:one)

    # Matches fixture api_tokens(:one)
    @auth_header = { "Authorization" => "Bearer ups_test_one_abcdef1234567890" }
  end

  test "should get index" do
    get api_v1_status_page_webhooks_url(@status_page), headers: @auth_header
    assert_response :success

    json = JSON.parse(response.body)
    assert json.key?("webhooks")
  end

  test "should get show" do
    get api_v1_status_page_webhook_url(@status_page, @webhook), headers: @auth_header
    assert_response :success

    json = JSON.parse(response.body)
    assert json.key?("webhook")
  end

  test "should create webhook" do
    assert_difference("Webhook.count") do
      post api_v1_status_page_webhooks_url(@status_page), headers: @auth_header, params: {
        webhook: { name: "New Webhook", url: "https://example.com/new-hook", events: ["incident.created"] }
      }
    end

    assert_response :created
  end

  test "should update webhook" do
    patch api_v1_status_page_webhook_url(@status_page, @webhook), headers: @auth_header, params: {
      webhook: { name: "Updated Webhook" }
    }

    assert_response :ok
    @webhook.reload
    assert_equal "Updated Webhook", @webhook.name
  end

  test "should destroy webhook" do
    assert_difference("Webhook.count", -1) do
      delete api_v1_status_page_webhook_url(@status_page, @webhook), headers: @auth_header
    end

    assert_response :no_content
  end
end
