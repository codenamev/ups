require "test_helper"

class StatusPagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = accounts(:one)
    @user = users(:one)
    @status_page = status_pages(:one)
    # Upgrade to pro plan so plan limits don't block test operations
    sign_in_as(@user)
  end

  test "should get index" do
    get status_pages_url
    assert_response :success
    assert_includes response.body, @status_page.name
  end

  test "should get new" do
    get new_status_page_url
    assert_response :success
    assert_includes response.body, "Create Status Page"
  end

  test "should create status_page" do
    assert_difference("StatusPage.count") do
      post status_pages_url, params: {
        status_page: {
          name: "Test Status Page",
          description: "A test status page",
          slug: "test-status-page"
        }
      }
    end

    assert_redirected_to status_page_url(StatusPage.last)
    assert_equal @account, StatusPage.last.account
  end

  test "should not create status_page without name" do
    assert_no_difference("StatusPage.count") do
      post status_pages_url, params: {
        status_page: {
          description: "A test status page",
          slug: "test-status-page"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "should show status_page" do
    get status_page_url(@status_page)
    assert_response :success
    assert_includes response.body, @status_page.name
  end

  test "should get edit" do
    get edit_status_page_url(@status_page)
    assert_response :success
    assert_includes response.body, "Edit Status Page"
  end

  test "should update status_page" do
    patch status_page_url(@status_page), params: {
      status_page: {
        name: "Updated Status Page",
        description: "Updated description"
      }
    }
    assert_redirected_to status_page_url(@status_page)

    @status_page.reload
    assert_equal "Updated Status Page", @status_page.name
    assert_equal "Updated description", @status_page.description
  end

  test "should not update status_page without name" do
    patch status_page_url(@status_page), params: {
      status_page: {
        name: "",
        description: "Updated description"
      }
    }
    assert_response :unprocessable_entity

    @status_page.reload
    assert_not_equal "", @status_page.name
  end

  test "should destroy status_page" do
    # Create a fresh status page without dependent records from fixtures
    destroyable = StatusPage.create!(name: "Deletable", slug: "deletable", account: @account)

    assert_difference("StatusPage.count", -1) do
      delete status_page_url(destroyable)
    end

    assert_redirected_to status_pages_url
  end

  test "should scope status pages to current account" do
    other_account = Account.create!(name: "Other Account")
    other_status_page = StatusPage.create!(
      name: "Other Status Page",
      slug: "other-status-page",
      account: other_account
    )

    get status_pages_url
    assert_response :success
    assert_includes response.body, @status_page.name
    assert_not_includes response.body, other_status_page.name
  end
end
