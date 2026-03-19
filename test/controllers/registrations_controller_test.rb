require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "should get new registration page" do
    get new_registration_url
    assert_response :success
  end

  test "should get new via sign_up alias" do
    get sign_up_url
    assert_response :success
  end

  test "should get new via register alias" do
    get register_url
    assert_response :success
  end

  test "should redirect to dashboard if already signed in" do
    user = users(:one)
    sign_in_as(user)

    get new_registration_url
    assert_redirected_to dashboard_path
  end

  test "should create new user with valid email" do
    email = "brand-new-user@example.com"

    assert_difference "User.count", 1 do
      assert_emails 1 do
        post registrations_url, params: { email_address: email }
      end
    end

    assert_redirected_to new_registration_path
    assert_match(/Welcome/, flash[:notice])

    user = User.find_by(email: email)
    assert user.present?
    assert user.primary_account.present?
  end

  test "should redirect existing user to sign in" do
    existing_user = users(:one)

    assert_no_difference "User.count" do
      assert_emails 1 do
        post registrations_url, params: { email_address: existing_user.email }
      end
    end

    assert_redirected_to sign_in_path
    assert_match(/already exists/, flash[:notice])
  end

  test "should reject blank email" do
    assert_no_difference "User.count" do
      post registrations_url, params: { email_address: "" }
    end

    assert_redirected_to new_registration_path
    assert_equal "Please enter a valid email address", flash[:alert]
  end

  test "should reject nil email" do
    assert_no_difference "User.count" do
      post registrations_url, params: {}
    end

    assert_redirected_to new_registration_path
    assert_equal "Please enter a valid email address", flash[:alert]
  end

  test "should normalize email with whitespace and case" do
    email = "  NewSignup@Example.COM  "

    assert_emails 1 do
      post registrations_url, params: { email_address: email }
    end

    user = User.find_by(email: "newsignup@example.com")
    assert user.present?
  end
end
