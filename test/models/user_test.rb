require "test_helper"

class UserTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @account = accounts(:one)
  end

  # --- Validations ---

  test "valid user" do
    assert @user.valid?
  end

  test "requires email" do
    @user.email = nil
    assert_not @user.valid?
    assert_includes @user.errors[:email], "can't be blank"
  end

  test "requires unique email" do
    duplicate = @user.dup
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:email], "has already been taken"
  end

  test "requires valid email format" do
    @user.email = "not-an-email"
    assert_not @user.valid?
    assert_includes @user.errors[:email], "is invalid"
  end

  test "requires name" do
    @user.name = nil
    assert_not @user.valid?
    assert_includes @user.errors[:name], "can't be blank"
  end

  # --- Normalizers ---

  test "email is stripped and downcased" do
    user = User.new(name: "Test", email: "  FOO@BAR.COM  ")
    assert_equal "foo@bar.com", user.email
  end

  # --- Magic link token ---

  test "generates and finds by magic link token" do
    token = @user.generate_token_for(:magic_link)
    assert_not_nil token
    found = User.find_by_magic_link_token(token)
    assert_equal @user, found
  end

  test "find_by_magic_link_token returns nil for invalid token" do
    assert_nil User.find_by_magic_link_token("bogus_token")
  end

  # --- Instance methods ---

  test "can_access_account? returns true for associated account" do
    assert @user.can_access_account?(@account)
  end

  test "can_access_account? returns false for unassociated account" do
    other_account = accounts(:two)
    assert_not @user.can_access_account?(other_account)
  end

  test "role_for_account returns role from account_users" do
    account_user = account_users(:one)
    assert_equal account_user.role, @user.role_for_account(@account)
  end

  test "role_for_account returns member when no association" do
    other_account = accounts(:two)
    assert_equal "member", @user.role_for_account(other_account)
  end

  test "admin_for? returns true when role is admin" do
    account_users(:one).update!(role: "admin")
    assert @user.admin_for?(@account)
  end

  test "admin_for? returns false when role is not admin" do
    account_users(:one).update!(role: "member")
    assert_not @user.admin_for?(@account)
  end

  test "primary_account returns first account" do
    assert_equal @user.accounts.first, @user.primary_account
  end

  test "update_last_sign_in! updates timestamp" do
    freeze_time do
      @user.update_last_sign_in!
      assert_equal Time.current, @user.reload.last_sign_in_at
    end
  end

  # --- Associations ---

  test "has many accounts through account_users" do
    assert_respond_to @user, :accounts
    assert_respond_to @user, :account_users
  end

  test "has many incidents" do
    assert_respond_to @user, :incidents
  end

  test "has many api tokens" do
    assert_respond_to @user, :api_tokens
  end
end
