require "test_helper"

class AccountTest < ActiveSupport::TestCase
  setup do
    @account = accounts(:one)
  end

  # --- Validations ---

  test "valid account" do
    assert @account.valid?
  end

  test "requires name" do
    @account.name = nil
    assert_not @account.valid?
    assert_includes @account.errors[:name], "can't be blank"
  end

  test "requires slug" do
    @account.slug = nil
    assert_not @account.valid?
    assert_includes @account.errors[:slug], "can't be blank"
  end

  test "requires unique slug" do
    duplicate = @account.dup
    duplicate.slug = @account.slug
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:slug], "has already been taken"
  end

  test "slug must match format" do
    @account.slug = "Valid Slug!"
    assert_not @account.valid?
    assert_includes @account.errors[:slug], "is invalid"
  end

  test "slug allows lowercase alphanumeric and hyphens" do
    @account.slug = "my-valid-slug-123"
    assert @account.valid?
  end

  test "plan must be free, pro, or business" do
    @account.plan = "enterprise"
    assert_not @account.valid?
    assert_includes @account.errors[:plan], "is not included in the list"
  end

  test "plan accepts valid values" do
    %w[free pro business].each do |plan|
      @account.plan = plan
      assert @account.valid?, "#{plan} should be a valid plan"
    end
  end

  # --- Callbacks ---

  test "set_default_plan sets plan to free on new record" do
    account = Account.new(name: "New Co")
    assert_equal "free", account.plan
  end

  test "set_default_plan does not overwrite existing plan" do
    account = Account.new(name: "Pro Co", plan: "pro")
    assert_equal "pro", account.plan
  end

  test "set_slug generates slug from name on create" do
    account = Account.new(name: "My Great Company", plan: "free")
    account.valid?
    assert_equal "my-great-company", account.slug
  end

  test "set_slug does not overwrite existing slug" do
    account = Account.new(name: "My Great Company", slug: "custom-slug", plan: "free")
    account.valid?
    assert_equal "custom-slug", account.slug
  end

  # --- Instance methods ---

  test "current_plan returns the plan" do
    assert_equal "free", @account.current_plan
  end

  test "current_plan returns free when plan is nil" do
    @account.plan = nil
    # bypass validation for this test
    assert_equal "free", @account.current_plan
  end

  test "needs_onboarding? returns true when not onboarded" do
    @account.onboarded = false
    assert @account.needs_onboarding?
  end

  test "needs_onboarding? returns false when onboarded" do
    @account.onboarded = true
    assert_not @account.needs_onboarding?
  end

  test "mark_as_onboarded! sets onboarded to true" do
    @account.update!(onboarded: false)
    @account.mark_as_onboarded!
    assert @account.reload.onboarded?
  end

  test "status_pages_count returns number of status pages" do
    assert_equal @account.status_pages.count, @account.status_pages_count
  end

  test "components_count returns number of components" do
    assert_equal @account.components.count, @account.components_count
  end

  test "monitors_count returns number of status monitors" do
    assert_equal @account.status_monitors.count, @account.monitors_count
  end

  test "team_members_count returns number of users" do
    assert_equal @account.users.count, @account.team_members_count
  end

  # --- Associations ---

  test "has many status pages" do
    assert_respond_to @account, :status_pages
  end

  test "has many users through account_users" do
    assert_respond_to @account, :users
    assert_respond_to @account, :account_users
  end

  test "has many api tokens" do
    assert_respond_to @account, :api_tokens
  end

  test "destroying account destroys dependent status pages" do
    account = Account.create!(name: "Disposable Corp", plan: "free")
    StatusPage.create!(account: account, name: "Disposable Page", slug: "disposable-page-unique")
    assert_difference("StatusPage.count", -1) do
      account.destroy
    end
  end
end
