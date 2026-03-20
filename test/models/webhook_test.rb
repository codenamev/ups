require "test_helper"

class WebhookTest < ActiveSupport::TestCase
  setup do
    @webhook = webhooks(:one)
    @account = accounts(:one)
    @status_page = status_pages(:one)
  end

  # --- Associations ---

  test "belongs to account" do
    assert_equal @account, @webhook.account
  end

  test "belongs to status_page" do
    assert_equal @status_page, @webhook.status_page
  end

  test "has many webhook_deliveries" do
    assert_respond_to @webhook, :webhook_deliveries
  end

  # --- VALID_EVENTS constant ---

  test "VALID_EVENTS contains expected event types" do
    expected = %w[
      incident.created
      incident.updated
      incident.resolved
      component.status_changed
      page.overall_status_changed
    ]
    assert_equal expected, Webhook::VALID_EVENTS
  end

  test "VALID_EVENTS is frozen" do
    assert_predicate Webhook::VALID_EVENTS, :frozen?
  end

  # --- Validations ---

  test "valid with all required attributes" do
    webhook = Webhook.new(
      account: @account,
      status_page: @status_page,
      name: "My Webhook",
      url: "https://example.com/hook",
      events: "incident.created"
    )
    assert webhook.valid?
  end

  test "invalid without name" do
    @webhook.name = nil
    assert_not @webhook.valid?
    assert_includes @webhook.errors[:name], "can't be blank"
  end

  test "invalid with name exceeding 255 characters" do
    @webhook.name = "a" * 256
    assert_not @webhook.valid?
    assert @webhook.errors[:name].any? { |e| e.include?("too long") }
  end

  test "valid with name at 255 characters" do
    @webhook.name = "a" * 255
    assert @webhook.valid?
  end

  test "invalid without url" do
    @webhook.url = nil
    assert_not @webhook.valid?
    assert_includes @webhook.errors[:url], "can't be blank"
  end

  test "invalid with malformed url" do
    @webhook.url = "not-a-url"
    assert_not @webhook.valid?
    assert @webhook.errors[:url].any?
  end

  test "invalid with ftp url" do
    @webhook.url = "ftp://example.com/hook"
    assert_not @webhook.valid?
    assert @webhook.errors[:url].any?
  end

  test "valid with http url" do
    @webhook.url = "http://example.com/hook"
    assert @webhook.valid?
  end

  test "valid with https url" do
    @webhook.url = "https://example.com/hook"
    assert @webhook.valid?
  end

  test "invalid without events" do
    @webhook.events = nil
    assert_not @webhook.valid?
    assert_includes @webhook.errors[:events], "can't be blank"
  end

  test "invalid without secret_token on existing record" do
    @webhook.secret_token = nil
    assert_not @webhook.valid?
    assert_includes @webhook.errors[:secret_token], "can't be blank"
  end

  # --- Custom validation: events_must_be_valid ---

  test "invalid with unknown event types" do
    @webhook.events = "incident.created,bogus.event"
    assert_not @webhook.valid?
    assert @webhook.errors[:events].any? { |e| e.include?("bogus.event") }
  end

  test "valid with all valid event types" do
    @webhook.events = Webhook::VALID_EVENTS.join(",")
    assert @webhook.valid?
  end

  # --- Callbacks ---

  test "generate_secret_token sets token on create when blank" do
    webhook = Webhook.new(
      account: @account,
      status_page: @status_page,
      name: "New Hook",
      url: "https://example.com/new",
      events: "incident.created"
    )
    webhook.valid?
    assert_not_nil webhook.secret_token
    assert_equal 64, webhook.secret_token.length # hex(32) = 64 chars
  end

  test "generate_secret_token does not overwrite existing token" do
    webhook = Webhook.new(
      account: @account,
      status_page: @status_page,
      name: "New Hook",
      url: "https://example.com/new",
      events: "incident.created",
      secret_token: "my_custom_token"
    )
    webhook.valid?
    assert_equal "my_custom_token", webhook.secret_token
  end

  test "normalize_events converts array to comma-separated string" do
    webhook = Webhook.new(
      account: @account,
      status_page: @status_page,
      name: "Array Hook",
      url: "https://example.com/hook",
      events: [ "incident.created", "incident.updated" ]
    )
    webhook.valid?
    assert_equal "incident.created,incident.updated", webhook.events
  end

  test "normalize_events parses JSON array string" do
    webhook = Webhook.new(
      account: @account,
      status_page: @status_page,
      name: "JSON Hook",
      url: "https://example.com/hook",
      events: '["incident.created","incident.resolved"]'
    )
    webhook.valid?
    assert_equal "incident.created,incident.resolved", webhook.events
  end

  test "normalize_events adds error for invalid JSON" do
    webhook = Webhook.new(
      account: @account,
      status_page: @status_page,
      name: "Bad JSON Hook",
      url: "https://example.com/hook",
      events: "[invalid json"
    )
    webhook.valid?
    assert @webhook.errors[:events].any? || webhook.errors[:events].any?
  end

  # --- SSRF protection: validate_not_internal_url ---

  test "rejects http://localhost URL" do
    @webhook.url = "http://localhost/hook"
    assert_not @webhook.valid?
    assert @webhook.errors[:url].any? { |e| e.include?("internal") || e.include?("private") }
  end

  test "rejects http://127.0.0.1 URL" do
    @webhook.url = "http://127.0.0.1/hook"
    assert_not @webhook.valid?
    assert @webhook.errors[:url].any? { |e| e.include?("internal") || e.include?("private") }
  end

  test "rejects http://0.0.0.0 URL" do
    @webhook.url = "http://0.0.0.0/hook"
    assert_not @webhook.valid?
    assert @webhook.errors[:url].any? { |e| e.include?("internal") || e.include?("private") }
  end

  test "rejects http://10.0.0.1 URL (private range)" do
    @webhook.url = "http://10.0.0.1/hook"
    assert_not @webhook.valid?
    assert @webhook.errors[:url].any? { |e| e.include?("internal") || e.include?("private") }
  end

  test "rejects http://172.16.0.1 URL (private range)" do
    @webhook.url = "http://172.16.0.1/hook"
    assert_not @webhook.valid?
    assert @webhook.errors[:url].any? { |e| e.include?("internal") || e.include?("private") }
  end

  test "rejects http://192.168.1.1 URL (private range)" do
    @webhook.url = "http://192.168.1.1/hook"
    assert_not @webhook.valid?
    assert @webhook.errors[:url].any? { |e| e.include?("internal") || e.include?("private") }
  end

  test "rejects http://[::1] URL (IPv6 localhost)" do
    @webhook.url = "http://[::1]/hook"
    assert_not @webhook.valid?
    assert @webhook.errors[:url].any? { |e| e.include?("internal") || e.include?("private") }
  end

  test "accepts http://example.com (valid external URL)" do
    @webhook.url = "http://example.com/hook"
    assert @webhook.valid?
  end

  test "accepts https://hooks.slack.com/services/xxx (valid external URL)" do
    @webhook.url = "https://hooks.slack.com/services/xxx"
    assert @webhook.valid?
  end

  # --- Scope ---

  test "active scope returns only active webhooks" do
    active_hooks = Webhook.active
    active_hooks.each do |hook|
      assert hook.active?
    end
  end

  # --- Instance methods ---

  test "event_types returns array of event strings" do
    @webhook.events = "incident.created,incident.updated"
    assert_equal %w[incident.created incident.updated], @webhook.event_types
  end

  test "event_types returns empty array when events is blank" do
    @webhook.events = ""
    assert_equal [], @webhook.event_types
  end

  test "event_types strips whitespace" do
    @webhook.events = "incident.created , incident.updated"
    assert_equal %w[incident.created incident.updated], @webhook.event_types
  end

  test "event_types= sets events from array" do
    @webhook.event_types = %w[incident.created incident.resolved]
    assert_equal "incident.created,incident.resolved", @webhook.events
  end

  test "event_types= handles single element" do
    @webhook.event_types = [ "incident.created" ]
    assert_equal "incident.created", @webhook.events
  end

  test "subscribes_to? returns true for subscribed event" do
    @webhook.events = "incident.created,incident.updated"
    assert @webhook.subscribes_to?("incident.created")
  end

  test "subscribes_to? returns false for unsubscribed event" do
    @webhook.events = "incident.created"
    assert_not @webhook.subscribes_to?("incident.resolved")
  end

  test "subscribes_to? works with symbol argument" do
    @webhook.events = "incident.created"
    assert @webhook.subscribes_to?(:"incident.created")
  end
end
