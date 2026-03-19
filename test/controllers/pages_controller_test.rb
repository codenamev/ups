require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "should get home page" do
    get root_url
    assert_response :success
  end

  test "should redirect authenticated users to dashboard" do
    user = users(:one)
    sign_in_as(user)

    get root_url
    assert_redirected_to dashboard_path
  end

  test "should not require authentication for home" do
    get root_url
    assert_response :success
    assert_not_equal new_session_url, response.redirect_url
  end

  private

  def sign_in_as(user)
    token = user.generate_token_for(:magic_link)
    get verify_magic_link_url(token: token)
  end
end
