require "test_helper"

class UseCasesControllerTest < ActionDispatch::IntegrationTest
  test "should show saas use case" do
    get use_case_url(use_case: "saas")
    assert_response :success
  end

  test "should show api-providers use case" do
    get use_case_url(use_case: "api-providers")
    assert_response :success
  end

  test "should show indie-hackers use case" do
    get use_case_url(use_case: "indie-hackers")
    assert_response :success
  end

  test "should return 404 for unknown use case" do
    assert_raises(ActionController::UrlGenerationError) do
      get use_case_url(use_case: "unknown")
    end
  end

  test "should not require authentication" do
    get use_case_url(use_case: "saas")
    assert_response :success
    assert_not_equal new_session_url, response.redirect_url
  end
end
