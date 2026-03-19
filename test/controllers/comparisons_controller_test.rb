require "test_helper"

class ComparisonsControllerTest < ActionDispatch::IntegrationTest
  test "should show statuspage comparison" do
    get comparison_url(competitor: "statuspage")
    assert_response :success
  end

  test "should show cachet comparison" do
    get comparison_url(competitor: "cachet")
    assert_response :success
  end

  test "should show betteruptime comparison" do
    get comparison_url(competitor: "betteruptime")
    assert_response :success
  end

  test "should return 404 for unknown competitor" do
    assert_raises(ActionController::UrlGenerationError) do
      get comparison_url(competitor: "unknown")
    end
  end

  test "should not require authentication" do
    get comparison_url(competitor: "statuspage")
    assert_response :success
    assert_not_equal new_session_url, response.redirect_url
  end
end
