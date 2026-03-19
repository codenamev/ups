require "test_helper"

class ApiTokenTest < ActiveSupport::TestCase
  setup do
    @api_token = api_tokens(:one)
    @account = accounts(:one)
    @user = users(:one)
  end

  # --- Validations ---

  test "valid api token" do
    assert @api_token.valid?
  end

  test "requires name" do
    @api_token.name = nil
    assert_not @api_token.valid?
    assert_includes @api_token.errors[:name], "can't be blank"
  end

  test "requires unique token_prefix" do
    # Create a second token with the same prefix directly in the DB
    duplicate = ApiToken.create!(account: @account, user: @user, name: "Dupe")
    duplicate.update_columns(token_prefix: @api_token.token_prefix)

    # Now validate the duplicate record
    duplicate.reload
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:token_prefix], "has already been taken"
  end

  test "requires token_digest" do
    @api_token.token_digest = nil
    assert_not @api_token.valid?
    assert_includes @api_token.errors[:token_digest], "can't be blank"
  end

  # --- Callbacks ---

  test "generate_token_digest sets token_prefix and token_digest on create" do
    token = ApiToken.new(account: @account, user: @user, name: "New Token")
    token.valid?
    assert token.token_prefix.present?
    assert token.token_digest.present?
  end

  test "generate_token_digest makes full_token available after create" do
    token = ApiToken.create!(account: @account, user: @user, name: "New Token")
    assert token.full_token.present?
    assert token.full_token.start_with?("ups_test_")
  end

  test "full_token is not available on a fresh lookup" do
    token = ApiToken.create!(account: @account, user: @user, name: "New Token")
    found = ApiToken.find(token.id)
    assert_nil found.full_token
  end

  # --- Class methods ---

  test "authenticate returns api token for valid token" do
    token = ApiToken.create!(account: @account, user: @user, name: "Auth Token")
    full_token = token.full_token
    assert_not_nil full_token

    authenticated = ApiToken.authenticate(full_token)
    assert_equal token, authenticated
  end

  test "authenticate updates last_used_at" do
    token = ApiToken.create!(account: @account, user: @user, name: "Auth Token")
    full_token = token.full_token

    freeze_time do
      ApiToken.authenticate(full_token)
      assert_equal Time.current, token.reload.last_used_at
    end
  end

  test "authenticate returns nil for nil token" do
    assert_nil ApiToken.authenticate(nil)
  end

  test "authenticate returns nil for empty string" do
    assert_nil ApiToken.authenticate("")
  end

  test "authenticate returns nil for invalid token" do
    assert_nil ApiToken.authenticate("ups_test_bogus_invalidtoken")
  end

  test "authenticate returns nil for wrong digest" do
    token = ApiToken.create!(account: @account, user: @user, name: "Auth Token")
    # Use correct prefix but wrong suffix
    bad_token = "#{token.token_prefix}_wrongdigest"
    assert_nil ApiToken.authenticate(bad_token)
  end

  # --- Instance methods ---

  test "regenerate_token! generates new token and returns full token" do
    token = ApiToken.create!(account: @account, user: @user, name: "Regen Token")
    old_prefix = token.token_prefix
    old_digest = token.token_digest

    new_full_token = token.regenerate_token!
    assert new_full_token.present?
    assert_not_equal old_prefix, token.token_prefix
    assert_not_equal old_digest, token.token_digest
  end

  test "masked_token returns prefix with masked suffix" do
    assert_equal "#{@api_token.token_prefix}_****", @api_token.masked_token
  end

  # --- Associations ---

  test "belongs to account" do
    assert_equal @account, @api_token.account
  end

  test "belongs to user" do
    assert_equal @user, @api_token.user
  end

  test "has many api requests" do
    assert_respond_to @api_token, :api_requests
  end
end
