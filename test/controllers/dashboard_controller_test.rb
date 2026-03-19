require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = accounts(:one)
    @user = users(:one)
    sign_in_as(@user)
  end

  test "should get index when authenticated" do
    get dashboard_url
    assert_response :success
  end

  test "should redirect to login when not authenticated" do
    reset!
    get dashboard_url
    assert_redirected_to new_session_path
  end

  test "should display status pages" do
    get dashboard_url
    assert_response :success
    assert_includes response.body, status_pages(:one).name
  end

  test "should display stats" do
    get dashboard_url
    assert_response :success
    assert_select "body"
  end

  test "should scope data to current account" do
    get dashboard_url
    assert_response :success

    # Should include account one's status page
    assert_includes response.body, status_pages(:one).name
    # Should NOT include account two's status page
    assert_not_includes response.body, status_pages(:two).name
  end

  test "should load with active incidents in stats" do
    status_page = status_pages(:one)
    Incident.create!(
      title: "Test Dashboard Incident",
      status: :investigating,
      impact: :minor,
      status_page: status_page,
      account: @account,
      user: @user,
      started_at: Time.current
    )

    get dashboard_url
    assert_response :success
    # The dashboard renders active incident count in stats
    assert_select "dd", text: "1"
  end
end
