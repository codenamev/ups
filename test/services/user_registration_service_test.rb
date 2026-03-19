require "test_helper"

class UserRegistrationServiceTest < ActiveSupport::TestCase
  test "registers new user with unique account" do
    email = "newuser@example.com"

    assert_difference 'User.count', 1 do
      assert_difference 'Account.count', 1 do
        assert_difference 'AccountUser.count', 1 do
          user = UserRegistrationService.register_or_find_user(email)

          assert_equal email, user.email
          assert_equal "Newuser", user.name
          assert user.accounts.present?

          account = user.primary_account
          assert_equal "Newuser", account.name
          assert_equal "newuser", account.slug
          assert_equal "free", account.plan

          account_user = AccountUser.find_by(user: user, account: account)
          assert_equal "owner", account_user.role
        end
      end
    end
  end

  test "returns existing user without creating duplicates" do
    existing_user = users(:one)

    assert_no_difference ['User.count', 'Account.count', 'AccountUser.count'] do
      user = UserRegistrationService.register_or_find_user(existing_user.email)
      assert_equal existing_user, user
    end
  end

  test "handles duplicate account slugs by adding counter" do
    # Create existing account with slug "testuser"
    existing_account = accounts(:one)
    existing_account.update!(slug: "testuser")

    email = "testuser@example.com"
    user = UserRegistrationService.register_or_find_user(email)

    # Should create account with "testuser-1" slug
    assert_equal "testuser-1", user.primary_account.slug
  end

  test "normalizes email addresses" do
    user1 = UserRegistrationService.register_or_find_user("  Test@Example.COM  ")
    user2 = UserRegistrationService.register_or_find_user("test@example.com")

    assert_equal user1, user2
    assert_equal "test@example.com", user1.email
  end
end
