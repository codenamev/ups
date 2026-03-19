require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "create registers new user and sends magic link" do
    email = "newuser@example.com"

    assert_difference ['User.count', 'Account.count', 'AccountUser.count'], 1 do
      assert_emails 1 do
        post sessions_path, params: { email_address: email }
      end
    end

    assert_redirected_to new_session_path
    assert_equal "Check your email for a sign-in link", flash[:notice]

    user = User.find_by(email: email)
    assert user.present?
    assert_equal "Newuser", user.name
    assert user.primary_account.present?
    assert_equal "owner", user.role_for_account(user.primary_account)
  end

  test "create sends magic link to existing user without duplicating" do
    existing_user = users(:one)

    assert_no_difference ['User.count', 'Account.count', 'AccountUser.count'] do
      assert_emails 1 do
        post sessions_path, params: { email_address: existing_user.email }
      end
    end

    assert_redirected_to new_session_path
    assert_equal "Check your email for a sign-in link", flash[:notice]
  end

  test "create normalizes email addresses" do
    email = "  NewUser@Example.COM  "
    normalized_email = "newuser@example.com"

    post sessions_path, params: { email_address: email }

    user = User.find_by(email: normalized_email)
    assert user.present?
    assert_equal normalized_email, user.email
  end

  test "create handles blank email" do
    post sessions_path, params: { email_address: "" }

    assert_redirected_to new_session_path
    assert_equal "Please enter a valid email address", flash[:alert]
  end
end
