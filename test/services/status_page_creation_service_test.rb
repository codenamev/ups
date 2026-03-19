require "test_helper"

class StatusPageCreationServiceTest < ActiveSupport::TestCase
  setup do
    @account = accounts(:one)
  end

  test "creates status page with default settings when valid" do
    service = StatusPageCreationService.new(
      name: "API Status",
      description: "API service status page",
      account: @account
    )

    assert_difference "StatusPage.count", 1 do
      assert_difference "Component.count", 3 do # API, Website, Dashboard
        result = service.call

        assert result.success?
        assert_nil result.error
        assert_not_nil result.status_page

        status_page = result.status_page
        assert_equal "API Status", status_page.name
        assert_equal "api-status", status_page.slug
        assert_equal "API service status page", status_page.description
        assert_equal @account, status_page.account
      end
    end
  end

  test "creates default components in correct order" do
    service = StatusPageCreationService.new(
      name: "Test Status",
      account: @account
    )

    result = service.call
    assert result.success?

    status_page = result.status_page
    components = status_page.components.order(:position)

    assert_equal 3, components.count
    assert_equal "API", components[0].name
    assert_equal "Core API services", components[0].description
    assert_equal 1, components[0].position
    assert components[0].status_operational?
    assert components[0].visible?

    assert_equal "Website", components[1].name
    assert_equal "Main website and dashboard", components[1].description
    assert_equal 2, components[1].position

    assert_equal "Dashboard", components[2].name
    assert_equal "User dashboard and interface", components[2].description
    assert_equal 3, components[2].position
  end

  test "creates default page settings" do
    service = StatusPageCreationService.new(
      name: "Test Status",
      account: @account
    )

    result = service.call
    status_page = result.status_page

    assert_not_nil status_page.page_setting
    assert_equal "UTC", status_page.timezone
    assert_equal "light", status_page.theme
    assert_not status_page.maintenance_mode
  end

  test "creates default branding" do
    service = StatusPageCreationService.new(
      name: "Test Status",
      account: @account
    )

    result = service.call
    status_page = result.status_page

    assert_not_nil status_page.branding
    assert_equal "#2563eb", status_page.primary_color
    assert_nil status_page.logo_url
    assert_nil status_page.custom_domain
    assert_nil status_page.favicon_url
  end

  test "auto-generates slug from name when not provided" do
    service = StatusPageCreationService.new(
      name: "My Awesome API Status",
      account: @account
    )

    result = service.call
    assert result.success?
    assert_equal "my-awesome-api-status", result.status_page.slug
  end

  test "uses provided slug when given" do
    service = StatusPageCreationService.new(
      name: "Test Status",
      slug: "custom-slug",
      account: @account
    )

    result = service.call
    assert result.success?
    assert_equal "custom-slug", result.status_page.slug
  end

  test "validates required fields" do
    service = StatusPageCreationService.new(
      name: "", # Missing name
      account: @account
    )

    result = service.call
    assert_not result.success?
    assert_includes result.error, "Name can't be blank"
  end

  test "validates account presence" do
    service = StatusPageCreationService.new(
      name: "Test Status"
      # Missing account
    )

    result = service.call
    assert_not result.success?
    assert_includes result.error, "Account can't be blank"
  end

  test "validates slug format" do
    service = StatusPageCreationService.new(
      name: "Test Status",
      slug: "Invalid_Slug!", # Invalid characters
      account: @account
    )

    result = service.call
    assert_not result.success?
    assert_includes result.error, "Slug is invalid"
  end

  test "handles creation failure gracefully" do
    # Use a duplicate slug to force a failure
    StatusPage.create!(name: "Existing", slug: "test-status", account: @account)

    service = StatusPageCreationService.new(
      name: "Test Status",
      slug: "test-status",
      account: @account
    )

    result = service.call
    assert_not result.success?
    assert_not_nil result.error
  end

  test "creation is atomic - rolls back on failure" do
    # Use a duplicate slug to force a failure
    StatusPage.create!(name: "Existing", slug: "atomic-test", account: @account)

    service = StatusPageCreationService.new(
      name: "Atomic Test",
      slug: "atomic-test",
      account: @account
    )

    original_count = StatusPage.count
    result = service.call
    assert_not result.success?
    assert_equal original_count, StatusPage.count
  end
end
