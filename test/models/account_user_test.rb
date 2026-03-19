require "test_helper"

class AccountUserTest < ActiveSupport::TestCase
  setup do
    @account_user = account_users(:one)
    @account = accounts(:one)
    @user = users(:one)
  end

  # --- Associations ---

  test "belongs to account" do
    assert_equal @account, @account_user.account
  end

  test "belongs to user" do
    assert_equal @user, @account_user.user
  end

  # --- Validations: role inclusion ---

  test "valid with owner role" do
    @account_user.role = "owner"
    assert @account_user.valid?
  end

  test "valid with admin role" do
    @account_user.role = "admin"
    assert @account_user.valid?
  end

  test "valid with member role" do
    @account_user.role = "member"
    assert @account_user.valid?
  end

  test "invalid with unrecognized role" do
    @account_user.role = "superadmin"
    assert_not @account_user.valid?
    assert @account_user.errors[:role].any?
  end

  test "invalid with nil role" do
    @account_user.role = nil
    assert_not @account_user.valid?
    assert @account_user.errors[:role].any?
  end

  test "invalid with empty string role" do
    @account_user.role = ""
    assert_not @account_user.valid?
    assert @account_user.errors[:role].any?
  end

  # --- Validations: uniqueness of account_id scoped to user_id ---

  test "invalid with duplicate account and user combination" do
    duplicate = AccountUser.new(
      account: @account,
      user: @user,
      role: "member"
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:account_id], "has already been taken"
  end

  test "valid with same account but different user" do
    other_user = users(:two)
    # Remove existing account_user for other_user on this account if any
    AccountUser.where(account: @account, user: other_user).destroy_all
    account_user = AccountUser.new(
      account: @account,
      user: other_user,
      role: "member"
    )
    assert account_user.valid?
  end

  test "valid with same user but different account" do
    other_account = accounts(:two)
    # Remove existing account_user for this user on other_account if any
    AccountUser.where(account: other_account, user: @user).destroy_all
    account_user = AccountUser.new(
      account: other_account,
      user: @user,
      role: "member"
    )
    assert account_user.valid?
  end

  # --- Default role ---

  test "default role is member from schema" do
    account_user = AccountUser.new
    assert_equal "member", account_user.role
  end
end
