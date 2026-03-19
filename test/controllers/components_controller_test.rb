require "test_helper"

class ComponentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = accounts(:one)
    @user = users(:one)
    @status_page = status_pages(:one)
    @component = components(:one)
    # Upgrade to pro plan so plan limits don't block test operations
    sign_in_as(@user)
  end

  test "should get index" do
    get status_page_components_url(@status_page)
    assert_response :success
    assert_includes response.body, @component.name
  end

  test "should get new" do
    get new_status_page_component_url(@status_page)
    assert_response :success
  end

  test "should create component" do
    assert_difference("Component.count") do
      post status_page_components_url(@status_page), params: {
        component: {
          name: "Test Component",
          description: "A test component",
          status: "operational",
          visible: true
        }
      }
    end

    component = Component.last
    assert_equal @status_page, component.status_page
    assert_equal @account, component.account
    assert_redirected_to status_page_component_url(@status_page, component)
  end

  test "should not create component without name" do
    assert_no_difference("Component.count") do
      post status_page_components_url(@status_page), params: {
        component: {
          description: "A test component",
          status: "operational"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "should show component" do
    get status_page_component_url(@status_page, @component)
    assert_response :success
    assert_includes response.body, @component.name
  end

  test "should get edit" do
    get edit_status_page_component_url(@status_page, @component)
    assert_response :success
  end

  test "should update component" do
    patch status_page_component_url(@status_page, @component), params: {
      component: {
        name: "Updated Component",
        description: "Updated description",
        status: "degraded_performance"
      }
    }

    @component.reload
    assert_equal "Updated Component", @component.name
    assert_equal "Updated description", @component.description
    assert_equal "degraded_performance", @component.status
  end

  test "should not update component without name" do
    original_name = @component.name

    patch status_page_component_url(@status_page, @component), params: {
      component: {
        name: "",
        description: "Updated description"
      }
    }
    assert_response :unprocessable_entity

    @component.reload
    assert_equal original_name, @component.name
  end

  test "should destroy component" do
    # Create a fresh component without dependent records from fixtures
    destroyable = Component.create!(
      name: "Destroyable",
      status_page: @status_page,
      account: @account,
      status: "operational"
    )

    assert_difference("Component.count", -1) do
      delete status_page_component_url(@status_page, destroyable)
    end

    assert_redirected_to status_page_components_url(@status_page)
  end

  test "should set position automatically" do
    existing_component = Component.create!(
      name: "Existing Component",
      status_page: @status_page,
      account: @account,
      status: "operational"
    )

    post status_page_components_url(@status_page), params: {
      component: {
        name: "New Component",
        status: "operational"
      }
    }

    new_component = Component.last
    assert new_component.position > existing_component.position
  end

  test "should handle turbo stream responses" do
    post status_page_components_url(@status_page),
         params: { component: { name: "Test Component", status: "operational" } },
         headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
  end

  test "should scope components to status page" do
    other_status_page = StatusPage.create!(
      name: "Other Status Page",
      slug: "other-status-page",
      account: @account
    )

    other_component = Component.create!(
      name: "Other Component",
      status_page: other_status_page,
      account: @account,
      status: "operational"
    )

    get status_page_components_url(@status_page)
    assert_response :success
    assert_includes response.body, @component.name
    assert_not_includes response.body, other_component.name
  end
end
