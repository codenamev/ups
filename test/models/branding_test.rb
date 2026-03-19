require "test_helper"

class BrandingTest < ActiveSupport::TestCase
  setup do
    @branding = brandings(:one)
  end

  # -- Associations --

  test "belongs to status_page" do
    assert_respond_to @branding, :status_page
    assert_instance_of StatusPage, @branding.status_page
  end

  # -- Validations: primary_color --

  test "is valid with a proper hex color" do
    @branding.primary_color = "#1A2B3C"
    assert @branding.valid?
  end

  test "is valid when primary_color is blank" do
    @branding.primary_color = ""
    assert @branding.valid?
  end

  test "is valid when primary_color is nil" do
    @branding.primary_color = nil
    assert @branding.valid?
  end

  test "is invalid with a hex color missing the hash" do
    @branding.primary_color = "FF5733"
    assert_not @branding.valid?
    assert_includes @branding.errors[:primary_color], "is invalid"
  end

  test "is invalid with a short hex color" do
    @branding.primary_color = "#FFF"
    assert_not @branding.valid?
  end

  test "is invalid with a hex color containing non-hex characters" do
    @branding.primary_color = "#GGGGGG"
    assert_not @branding.valid?
  end

  test "is invalid with a hex color that is too long" do
    @branding.primary_color = "#FF5733AA"
    assert_not @branding.valid?
  end

  test "accepts lowercase hex digits in primary_color" do
    @branding.primary_color = "#aabbcc"
    assert @branding.valid?
  end

  test "accepts mixed case hex digits in primary_color" do
    @branding.primary_color = "#aAbBcC"
    assert @branding.valid?
  end

  # -- Validations: custom_domain --

  test "is valid with a unique custom_domain" do
    @branding.custom_domain = "unique-domain.example.com"
    assert @branding.valid?
  end

  test "is invalid with a duplicate custom_domain" do
    other = brandings(:two)
    @branding.custom_domain = other.custom_domain
    assert_not @branding.valid?
    assert_includes @branding.errors[:custom_domain], "has already been taken"
  end

  test "is valid when custom_domain is blank" do
    @branding.custom_domain = ""
    assert @branding.valid?
  end

  test "is valid when custom_domain is nil" do
    @branding.custom_domain = nil
    assert @branding.valid?
  end

  # -- Fixture sanity --

  test "fixtures are valid" do
    assert brandings(:one).valid?
    assert brandings(:two).valid?
  end
end
