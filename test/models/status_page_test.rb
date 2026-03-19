require "test_helper"

class StatusPageTest < ActiveSupport::TestCase
  setup do
    @status_page = status_pages(:one)
    @account = accounts(:one)
  end

  # --- Validations ---

  test "valid status page" do
    assert @status_page.valid?
  end

  test "requires name" do
    @status_page.name = nil
    @status_page.slug = "has-a-slug"
    assert_not @status_page.valid?
    assert_includes @status_page.errors[:name], "can't be blank"
  end

  test "requires slug" do
    @status_page.slug = nil
    @status_page.name = nil # prevent normalize_slug from regenerating it
    assert_not @status_page.valid?
    assert_includes @status_page.errors[:slug], "can't be blank"
  end

  test "slug must be unique within account" do
    duplicate = @status_page.dup
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:slug], "has already been taken"
  end

  test "slug can be reused across accounts" do
    other_account = accounts(:two)
    page = StatusPage.new(
      account: other_account,
      name: "Duplicate Slug Page",
      slug: @status_page.slug
    )
    assert page.valid?
  end

  # --- Callbacks ---

  test "normalize_slug downcases slug" do
    @status_page.slug = "MY-SLUG"
    @status_page.valid?
    assert_equal "my-slug", @status_page.slug
  end

  test "normalize_slug generates slug from name when slug is blank" do
    page = StatusPage.new(account: @account, name: "My New Page")
    page.valid?
    assert_equal "my-new-page", page.slug
  end

  test "create_default_settings creates page_setting after create" do
    page = StatusPage.create!(account: @account, name: "Settings Test", slug: "settings-test-unique")
    assert_not_nil page.page_setting
    assert_equal "UTC", page.page_setting.timezone
    assert_equal "light", page.page_setting.theme
  end

  test "create_default_settings creates branding after create" do
    page = StatusPage.create!(account: @account, name: "Branding Test", slug: "branding-test-unique")
    assert_not_nil page.branding
  end

  # --- Associations ---

  test "belongs to account" do
    assert_equal @account, @status_page.account
  end

  test "has many components" do
    assert_respond_to @status_page, :components
  end

  test "has many incidents" do
    assert_respond_to @status_page, :incidents
  end

  test "has many subscribers" do
    assert_respond_to @status_page, :subscribers
  end

  test "has one page setting" do
    assert_respond_to @status_page, :page_setting
  end

  test "has one branding" do
    assert_respond_to @status_page, :branding
  end

  test "destroying status page destroys dependent components" do
    page = StatusPage.create!(account: @account, name: "Destroy Test", slug: "destroy-test-unique")
    page.components.create!(name: "API", account: @account)
    assert_difference("Component.count", -1) do
      page.destroy
    end
  end

  # --- Delegation ---

  test "delegates timezone to page_setting" do
    assert_respond_to @status_page, :timezone
  end

  test "delegates theme to page_setting" do
    assert_respond_to @status_page, :theme
  end
end
