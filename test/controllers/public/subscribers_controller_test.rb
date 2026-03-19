require "test_helper"

class Public::SubscribersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @status_page = status_pages(:one)
    @subscriber = subscribers(:one)
  end

  test "should create subscriber with valid email" do
    assert_difference "Subscriber.count", 1 do
      post public_subscribe_url(slug: @status_page.slug), params: { email: "newsubscriber@example.com" }
    end

    assert_redirected_to public_status_page_path(@status_page.slug)
    assert_match(/subscribed/i, flash[:notice])
  end

  test "should reject duplicate subscriber email" do
    assert_no_difference "Subscriber.count" do
      post public_subscribe_url(slug: @status_page.slug), params: { email: @subscriber.email }
    end

    assert_redirected_to public_status_page_path(@status_page.slug)
    assert flash[:alert].present?
  end

  test "should reject invalid email" do
    assert_no_difference "Subscriber.count" do
      post public_subscribe_url(slug: @status_page.slug), params: { email: "not-an-email" }
    end

    assert_redirected_to public_status_page_path(@status_page.slug)
    assert flash[:alert].present?
  end

  test "should reject blank email" do
    assert_no_difference "Subscriber.count" do
      post public_subscribe_url(slug: @status_page.slug), params: { email: "" }
    end

    assert_redirected_to public_status_page_path(@status_page.slug)
    assert flash[:alert].present?
  end

  test "should destroy subscriber via confirmation token" do
    assert_difference "Subscriber.count", -1 do
      get public_unsubscribe_url(slug: @status_page.slug, token: @subscriber.confirmation_token)
    end

    assert_redirected_to public_status_page_path(@status_page.slug)
    assert_match(/unsubscribed/i, flash[:notice])
  end

  test "should return 404 for missing unsubscribe token" do
    get public_unsubscribe_url(slug: @status_page.slug, token: "nonexistent-token")
    assert_response :not_found
  end

  test "should return 404 for nonexistent status page" do
    post "/nonexistent-slug-xyz/subscribe", params: { email: "test@example.com" }
    assert_response :not_found
  end

  test "should allow same email to subscribe to different status pages" do
    other_status_page = status_pages(:two)

    assert_difference "Subscriber.count", 1 do
      post public_subscribe_url(slug: other_status_page.slug), params: { email: @subscriber.email }
    end

    assert_redirected_to public_status_page_path(other_status_page.slug)
  end
end
