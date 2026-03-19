require "test_helper"

class PageSettingTest < ActiveSupport::TestCase
  setup do
    @page_setting = page_settings(:one)
  end

  # -- Associations --

  test "belongs to status_page" do
    assert_respond_to @page_setting, :status_page
    assert_instance_of StatusPage, @page_setting.status_page
  end

  # -- Validations: timezone --

  test "is valid with a recognized timezone" do
    @page_setting.timezone = "UTC"
    assert @page_setting.valid?
  end

  test "is valid with Eastern Time timezone" do
    @page_setting.timezone = "Eastern Time (US & Canada)"
    assert @page_setting.valid?
  end

  test "is invalid with an unrecognized timezone" do
    @page_setting.timezone = "Fake/Timezone"
    assert_not @page_setting.valid?
    assert_includes @page_setting.errors[:timezone], "is not included in the list"
  end

  test "is invalid with a blank timezone" do
    @page_setting.timezone = ""
    assert_not @page_setting.valid?
  end

  test "is invalid with a nil timezone" do
    @page_setting.timezone = nil
    assert_not @page_setting.valid?
  end

  # -- Validations: theme --

  test "is valid with light theme" do
    @page_setting.theme = "light"
    assert @page_setting.valid?
  end

  test "is valid with dark theme" do
    @page_setting.theme = "dark"
    assert @page_setting.valid?
  end

  test "is valid with auto theme" do
    @page_setting.theme = "auto"
    assert @page_setting.valid?
  end

  test "is invalid with an unrecognized theme" do
    @page_setting.theme = "neon"
    assert_not @page_setting.valid?
    assert_includes @page_setting.errors[:theme], "is not included in the list"
  end

  test "is invalid with a blank theme" do
    @page_setting.theme = ""
    assert_not @page_setting.valid?
  end

  test "is invalid with a nil theme" do
    @page_setting.theme = nil
    assert_not @page_setting.valid?
  end

  # -- Fixture sanity --

  test "fixtures are valid" do
    assert page_settings(:one).valid?
    assert page_settings(:two).valid?
  end
end
