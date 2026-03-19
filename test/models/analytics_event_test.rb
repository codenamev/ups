require "test_helper"

# AnalyticsEvent has no dedicated model file (schema-only table).
# Define a minimal class so the tests can exercise the table.
class AnalyticsEvent < ApplicationRecord; end unless defined?(AnalyticsEvent)

class AnalyticsEventTest < ActiveSupport::TestCase
  test "can be created with valid attributes" do
    event = AnalyticsEvent.create!(
      event_type: "page_view",
      metadata: { page: "/status" },
      occurred_at: Time.current
    )
    assert event.persisted?
  end

  test "has expected attributes" do
    event = AnalyticsEvent.new
    assert_respond_to event, :event_type
    assert_respond_to event, :metadata
    assert_respond_to event, :occurred_at
    assert_respond_to event, :user_id
    assert_respond_to event, :created_at
    assert_respond_to event, :updated_at
  end

  test "can store JSON metadata" do
    metadata = { "browser" => "Chrome", "os" => "macOS", "referrer" => "https://example.com" }
    event = AnalyticsEvent.create!(
      event_type: "click",
      metadata: metadata,
      occurred_at: Time.current
    )
    event.reload
    assert_equal "Chrome", event.metadata["browser"]
    assert_equal "macOS", event.metadata["os"]
  end

  test "can be queried by event_type" do
    AnalyticsEvent.create!(event_type: "signup", occurred_at: Time.current)
    AnalyticsEvent.create!(event_type: "page_view", occurred_at: Time.current)

    assert_equal 1, AnalyticsEvent.where(event_type: "signup").count
  end
end
