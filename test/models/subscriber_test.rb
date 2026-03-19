require "test_helper"

class SubscriberTest < ActiveSupport::TestCase
  setup do
    @subscriber = subscribers(:one)
    @account = accounts(:one)
    @status_page = status_pages(:one)
  end

  # --- Validations ---

  test "valid subscriber" do
    assert @subscriber.valid?
  end

  test "requires email" do
    @subscriber.email = nil
    assert_not @subscriber.valid?
    assert_includes @subscriber.errors[:email], "can't be blank"
  end

  test "requires valid email format" do
    @subscriber.email = "not-an-email"
    assert_not @subscriber.valid?
    assert_includes @subscriber.errors[:email], "is invalid"
  end

  test "email must be unique within status page" do
    duplicate = @subscriber.dup
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:email], "has already been taken"
  end

  test "same email can exist on different status pages" do
    other_page = status_pages(:two)
    other_account = accounts(:two)
    subscriber = Subscriber.new(
      account: other_account,
      status_page: other_page,
      email: @subscriber.email
    )
    assert subscriber.valid?
  end

  # --- Scopes ---

  test "confirmed scope returns confirmed subscribers" do
    confirmed = Subscriber.confirmed
    assert confirmed.all?(&:confirmed?)
  end

  test "unconfirmed scope returns unconfirmed subscribers" do
    @subscriber.update_columns(confirmed: false)
    unconfirmed = Subscriber.unconfirmed
    assert_includes unconfirmed, @subscriber
  end

  test "subscribed scope returns subscribers without unsubscribed_at" do
    subscribed = Subscriber.subscribed
    assert subscribed.all? { |s| s.unsubscribed_at.nil? }
  end

  test "subscribed scope excludes unsubscribed" do
    @subscriber.update_columns(unsubscribed_at: Time.current)
    assert_not_includes Subscriber.subscribed, @subscriber
  end

  test "active scope returns confirmed and subscribed subscribers" do
    active = Subscriber.active
    assert active.all? { |s| s.confirmed? && s.unsubscribed_at.nil? }
  end

  # --- Callbacks ---

  test "generates confirmation token on create" do
    subscriber = Subscriber.create!(
      account: @account,
      status_page: @status_page,
      email: "new-subscriber-#{SecureRandom.hex(4)}@example.com"
    )
    assert_not_nil subscriber.confirmation_token
  end

  test "generates unsubscribe token on create" do
    subscriber = Subscriber.create!(
      account: @account,
      status_page: @status_page,
      email: "new-unsub-#{SecureRandom.hex(4)}@example.com"
    )
    assert_not_nil subscriber.unsubscribe_token
  end

  test "does not overwrite existing confirmation token" do
    subscriber = Subscriber.new(
      account: @account,
      status_page: @status_page,
      email: "preset-token-#{SecureRandom.hex(4)}@example.com",
      confirmation_token: "my-preset-token"
    )
    subscriber.save!
    assert_equal "my-preset-token", subscriber.confirmation_token
  end

  test "creates default notification preferences on create" do
    subscriber = Subscriber.create!(
      account: @account,
      status_page: @status_page,
      email: "prefs-test-#{SecureRandom.hex(4)}@example.com"
    )
    assert_equal 1, subscriber.notification_preferences.count
  end

  # --- Instance methods ---

  test "preferences_for returns existing preference for component" do
    pref = notification_preferences(:one)
    component = pref.component
    result = @subscriber.preferences_for(component)
    assert_equal pref, result
  end

  test "preferences_for builds default preference when none exists" do
    result = @subscriber.preferences_for(nil)
    # If no global preference found, it builds a new one
    assert result.is_a?(NotificationPreference)
  end

  # --- Associations ---

  test "belongs to account" do
    assert_equal @account, @subscriber.account
  end

  test "belongs to status page" do
    assert_equal @status_page, @subscriber.status_page
  end

  test "has many notification preferences" do
    assert_respond_to @subscriber, :notification_preferences
  end
end
