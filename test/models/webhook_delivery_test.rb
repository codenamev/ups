require "test_helper"

class WebhookDeliveryTest < ActiveSupport::TestCase
  setup do
    @delivery = webhook_deliveries(:one)
    @webhook = webhooks(:one)
  end

  # --- Associations ---

  test "belongs to webhook" do
    assert_equal @webhook, @delivery.webhook
  end

  # --- Constants ---

  test "MAX_RETRIES is 5" do
    assert_equal 5, WebhookDelivery::MAX_RETRIES
  end

  test "RETRY_DELAYS has 5 entries" do
    assert_equal 5, WebhookDelivery::RETRY_DELAYS.length
  end

  test "RETRY_DELAYS is frozen" do
    assert_predicate WebhookDelivery::RETRY_DELAYS, :frozen?
  end

  test "RETRY_DELAYS contains expected durations" do
    expected = [ 1.minute, 5.minutes, 30.minutes, 2.hours, 12.hours ]
    assert_equal expected, WebhookDelivery::RETRY_DELAYS
  end

  # --- Enum ---

  test "status enum defines pending" do
    delivery = WebhookDelivery.new(status: "pending")
    assert delivery.pending?
  end

  test "status enum defines delivered" do
    delivery = WebhookDelivery.new(status: "delivered")
    assert delivery.delivered?
  end

  test "status enum defines failed" do
    delivery = WebhookDelivery.new(status: "failed")
    assert delivery.failed?
  end

  test "status enum defines retrying" do
    delivery = WebhookDelivery.new(status: "retrying")
    assert delivery.retrying?
  end

  # --- Validations ---

  test "valid with all required attributes" do
    delivery = WebhookDelivery.new(
      webhook: @webhook,
      event_type: "incident.created",
      event_data: '{"id": 1}',
      status: "pending"
    )
    assert delivery.valid?
  end

  test "invalid without event_type" do
    delivery = WebhookDelivery.new(
      webhook: @webhook,
      event_data: '{"id": 1}',
      status: "pending"
    )
    assert_not delivery.valid?
    assert_includes delivery.errors[:event_type], "can't be blank"
  end

  test "invalid without event_data" do
    delivery = WebhookDelivery.new(
      webhook: @webhook,
      event_type: "incident.created",
      status: "pending"
    )
    assert_not delivery.valid?
    assert_includes delivery.errors[:event_data], "can't be blank"
  end

  test "idempotency_key must be unique" do
    duplicate = WebhookDelivery.new(
      webhook: @webhook,
      event_type: "incident.created",
      event_data: '{"id": 1}',
      idempotency_key: @delivery.idempotency_key,
      status: "pending"
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:idempotency_key], "has already been taken"
  end

  # --- Callback: generate_idempotency_key ---

  test "generates idempotency_key on create when blank" do
    delivery = WebhookDelivery.new(
      webhook: @webhook,
      event_type: "incident.created",
      event_data: '{"id": 1}',
      status: "pending"
    )
    delivery.valid?
    assert_not_nil delivery.idempotency_key
    assert_equal 32, delivery.idempotency_key.length # hex(16) = 32 chars
  end

  test "does not overwrite existing idempotency_key" do
    delivery = WebhookDelivery.new(
      webhook: @webhook,
      event_type: "incident.created",
      event_data: '{"id": 1}',
      idempotency_key: "custom-key-12345",
      status: "pending"
    )
    delivery.valid?
    assert_equal "custom-key-12345", delivery.idempotency_key
  end

  # --- Scopes ---

  test "failed_retries returns failed or retrying deliveries under max retries" do
    @delivery.update_columns(status: "failed", retries: 2)
    assert_includes WebhookDelivery.failed_retries, @delivery

    @delivery.update_columns(retries: 5)
    assert_not_includes WebhookDelivery.failed_retries, @delivery
  end

  test "failed_retries excludes delivered and pending" do
    @delivery.update_columns(status: "delivered", retries: 0)
    assert_not_includes WebhookDelivery.failed_retries, @delivery

    @delivery.update_columns(status: "pending", retries: 0)
    assert_not_includes WebhookDelivery.failed_retries, @delivery
  end

  test "ready_for_retry returns deliveries with old or nil last_retry_at" do
    @delivery.update_columns(status: "failed", retries: 1, last_retry_at: nil)
    assert_includes WebhookDelivery.ready_for_retry, @delivery

    @delivery.update_columns(last_retry_at: 10.minutes.ago)
    assert_includes WebhookDelivery.ready_for_retry, @delivery

    @delivery.update_columns(last_retry_at: 1.minute.ago)
    assert_not_includes WebhookDelivery.ready_for_retry, @delivery
  end

  # --- Instance methods ---

  test "can_retry? returns true when retries under max and status is failed" do
    @delivery.update_columns(status: "failed", retries: 3)
    @delivery.reload
    assert @delivery.can_retry?
  end

  test "can_retry? returns true when status is retrying" do
    @delivery.update_columns(status: "retrying", retries: 2)
    @delivery.reload
    assert @delivery.can_retry?
  end

  test "can_retry? returns false when retries at max" do
    @delivery.update_columns(status: "failed", retries: 5)
    @delivery.reload
    assert_not @delivery.can_retry?
  end

  test "can_retry? returns false when status is delivered" do
    @delivery.update_columns(status: "delivered", retries: 0)
    @delivery.reload
    assert_not @delivery.can_retry?
  end

  test "can_retry? returns false when status is pending" do
    @delivery.update_columns(status: "pending", retries: 0)
    @delivery.reload
    assert_not @delivery.can_retry?
  end

  test "next_retry_at returns nil when cannot retry" do
    @delivery.update_columns(status: "delivered", retries: 0)
    @delivery.reload
    assert_nil @delivery.next_retry_at
  end

  test "next_retry_at returns current time when last_retry_at is nil" do
    @delivery.update_columns(status: "failed", retries: 0, last_retry_at: nil)
    @delivery.reload
    freeze_time do
      assert_equal Time.current, @delivery.next_retry_at
    end
  end

  test "next_retry_at returns last_retry_at plus appropriate delay" do
    time = 1.hour.ago.change(usec: 0)
    @delivery.update_columns(status: "failed", retries: 1, last_retry_at: time)
    @delivery.reload
    expected = time + WebhookDelivery::RETRY_DELAYS[1]
    assert_equal expected, @delivery.next_retry_at
  end

  test "retry_delay returns correct delay for current retry count" do
    @delivery.update_columns(retries: 0)
    @delivery.reload
    assert_equal 1.minute, @delivery.retry_delay

    @delivery.update_columns(retries: 2)
    @delivery.reload
    assert_equal 30.minutes, @delivery.retry_delay
  end

  test "retry_delay returns last delay when retries exceeds array" do
    @delivery.update_columns(retries: 10)
    @delivery.reload
    assert_equal 12.hours, @delivery.retry_delay
  end

  test "mark_delivered! updates status and delivered_at" do
    @delivery.update_columns(status: "pending")
    freeze_time do
      @delivery.mark_delivered!(200, "OK")
      @delivery.reload
      assert @delivery.delivered?
      assert_equal Time.current, @delivery.delivered_at
      assert_equal 200, @delivery.response_status
      assert_equal "OK", @delivery.response_body
    end
  end

  test "mark_delivered! truncates response_body to 10000 chars" do
    @delivery.update_columns(status: "pending")
    long_body = "x" * 20_000
    @delivery.mark_delivered!(200, long_body)
    @delivery.reload
    assert @delivery.response_body.length <= 10_000
  end

  test "mark_delivered! accepts nil response_body" do
    @delivery.update_columns(status: "pending")
    @delivery.mark_delivered!(204)
    @delivery.reload
    assert @delivery.delivered?
    assert_nil @delivery.response_body
  end

  test "mark_failed! increments retries and sets retrying when can retry" do
    # increment! saves immediately, then can_retry? checks the new retries value
    # and the current status. After increment!(retries) from 0->1, status is still
    # what we set. Then update! sets status based on can_retry? with new retries.
    @delivery.update_columns(status: "failed", retries: 0)
    @delivery.reload
    @delivery.mark_failed!(500, "Server Error")
    @delivery.reload
    assert_equal 1, @delivery.retries
    assert @delivery.retrying?
    assert_not_nil @delivery.last_retry_at
    assert_equal 500, @delivery.response_status
  end

  test "mark_failed! sets failed status when retries exhausted" do
    # After increment from 4->5, can_retry? returns false (5 >= MAX_RETRIES)
    @delivery.update_columns(status: "retrying", retries: 4)
    @delivery.reload
    @delivery.mark_failed!(500)
    @delivery.reload
    assert_equal 5, @delivery.retries
    assert @delivery.failed?
  end

  test "parsed_event_data returns parsed JSON" do
    @delivery.event_data = '{"type":"incident.created","id":42}'
    result = @delivery.parsed_event_data
    assert_equal({ "type" => "incident.created", "id" => 42 }, result)
  end

  test "parsed_event_data memoizes result" do
    @delivery.event_data = '{"key":"value"}'
    first_call = @delivery.parsed_event_data
    assert_same first_call, @delivery.parsed_event_data
  end
end
