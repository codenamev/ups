require "test_helper"

class WebhookServiceTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @account = accounts(:one)
    @status_page = status_pages(:one)
    @incident = incidents(:one)

    # Deactivate any fixture webhooks to isolate tests
    Webhook.where(status_page: @status_page).update_all(active: false)

    # Create an active webhook subscribed to incident events
    @webhook = Webhook.create!(
      account: @account,
      status_page: @status_page,
      name: "Test Webhook",
      url: "https://example.com/test-webhook-service",
      events: "incident.created,incident.updated,incident.resolved,component.status_changed,page.overall_status_changed",
      active: true
    )

    @component = components(:one)
  end

  # --- deliver_incident_created ---

  test "deliver_incident_created creates webhook delivery for subscribing webhooks" do
    assert_difference -> { WebhookDelivery.count }, 1 do
      WebhookService.deliver_incident_created(@incident)
    end

    delivery = WebhookDelivery.last
    assert_equal "incident.created", delivery.event_type
    assert_equal @webhook.id, delivery.webhook_id
  end

  test "deliver_incident_created enqueues DeliverWebhookJob" do
    assert_enqueued_with(job: DeliverWebhookJob) do
      WebhookService.deliver_incident_created(@incident)
    end
  end

  test "deliver_incident_created skips inactive webhooks" do
    @webhook.update!(active: false)

    assert_no_difference -> { WebhookDelivery.count } do
      WebhookService.deliver_incident_created(@incident)
    end
  end

  test "deliver_incident_created skips webhooks not subscribed to event" do
    @webhook.update!(events: "incident.resolved")

    assert_no_difference -> { WebhookDelivery.count } do
      WebhookService.deliver_incident_created(@incident)
    end
  end

  # --- deliver_incident_updated ---

  test "deliver_incident_updated creates deliveries with correct event type" do
    WebhookService.deliver_incident_updated(@incident)

    delivery = WebhookDelivery.last
    assert_equal "incident.updated", delivery.event_type
  end

  # --- deliver_incident_resolved ---

  test "deliver_incident_resolved creates deliveries with correct event type" do
    WebhookService.deliver_incident_resolved(@incident)

    delivery = WebhookDelivery.last
    assert_equal "incident.resolved", delivery.event_type
  end

  # --- deliver_component_status_changed ---

  test "deliver_component_status_changed creates deliveries" do
    assert_difference -> { WebhookDelivery.count }, 1 do
      WebhookService.deliver_component_status_changed(@component, "operational")
    end

    delivery = WebhookDelivery.last
    assert_equal "component.status_changed", delivery.event_type

    data = JSON.parse(delivery.event_data)
    assert_equal "operational", data["component"]["previous_status"]
    assert_equal @component.name, data["component"]["name"]
  end

  # --- deliver_page_overall_status_changed ---

  test "deliver_page_overall_status_changed creates deliveries" do
    assert_difference -> { WebhookDelivery.count }, 1 do
      WebhookService.deliver_page_overall_status_changed(@status_page, "operational", "degraded_performance")
    end

    delivery = WebhookDelivery.last
    assert_equal "page.overall_status_changed", delivery.event_type

    data = JSON.parse(delivery.event_data)
    assert_equal "degraded_performance", data["status_page"]["overall_status"]
    assert_equal "operational", data["status_page"]["previous_overall_status"]
  end

  # --- incident_payload structure ---

  test "incident payload includes correct structure" do
    WebhookService.deliver_incident_created(@incident)

    delivery = WebhookDelivery.last
    data = JSON.parse(delivery.event_data)

    assert data.key?("event"), "Payload should include event key"
    assert data.key?("incident"), "Payload should include incident key"
    assert data.key?("status_page"), "Payload should include status_page key"

    assert_equal @incident.id, data["event"]["id"]
    assert_equal "incident", data["event"]["type"]
    assert_equal @incident.id, data["incident"]["id"]
    assert_equal @incident.title, data["incident"]["title"]
    assert_equal @status_page.id, data["status_page"]["id"]
    assert_equal @status_page.name, data["status_page"]["name"]
    assert_equal @status_page.slug, data["status_page"]["slug"]
  end

  # --- idempotency key ---

  test "idempotency key is deterministic for same inputs" do
    service = WebhookService.new
    event_data = { foo: "bar" }

    key1 = service.send(:generate_idempotency_key, @webhook, "incident.created", event_data)
    key2 = service.send(:generate_idempotency_key, @webhook, "incident.created", event_data)

    assert_equal key1, key2
    assert_equal 32, key1.length
  end

  test "idempotency key differs for different inputs" do
    service = WebhookService.new
    event_data = { foo: "bar" }

    key1 = service.send(:generate_idempotency_key, @webhook, "incident.created", event_data)
    key2 = service.send(:generate_idempotency_key, @webhook, "incident.updated", event_data)

    assert_not_equal key1, key2
  end

  # --- retry_failed_deliveries ---

  test "retry_failed_deliveries enqueues jobs for retryable deliveries" do
    delivery = @webhook.webhook_deliveries.create!(
      event_type: "incident.created",
      event_data: '{"test": true}',
      idempotency_key: SecureRandom.hex(16),
      status: "failed",
      retries: 0,
      last_retry_at: 10.minutes.ago
    )

    assert_enqueued_with(job: DeliverWebhookJob, args: [ delivery.id ]) do
      WebhookService.retry_failed_deliveries
    end
  end

  test "retry_failed_deliveries does not enqueue jobs for max-retried deliveries" do
    @webhook.webhook_deliveries.create!(
      event_type: "incident.created",
      event_data: '{"test": true}',
      idempotency_key: SecureRandom.hex(16),
      status: "failed",
      retries: WebhookDelivery::MAX_RETRIES,
      last_retry_at: 10.minutes.ago
    )

    assert_no_enqueued_jobs(only: DeliverWebhookJob) do
      WebhookService.retry_failed_deliveries
    end
  end
end
