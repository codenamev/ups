require "test_helper"

class IdempotencyKeyTest < ActiveSupport::TestCase
  setup do
    @account = accounts(:one)
  end

  test "validates presence of key" do
    ik = IdempotencyKey.new(account: @account, key: nil, response_status: 200, expires_at: 1.hour.from_now)
    assert_not ik.valid?
    assert_includes ik.errors[:key], "can't be blank"
  end

  test "validates uniqueness of key scoped to account" do
    IdempotencyKey.create!(
      account: @account,
      key: "unique-key-123",
      response_status: 200,
      expires_at: 1.hour.from_now
    )

    duplicate = IdempotencyKey.new(
      account: @account,
      key: "unique-key-123",
      response_status: 200,
      expires_at: 1.hour.from_now
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:key], "has already been taken"
  end

  test "allows same key for different accounts" do
    other_account = accounts(:two)

    IdempotencyKey.create!(
      account: @account,
      key: "shared-key",
      response_status: 200,
      expires_at: 1.hour.from_now
    )

    other = IdempotencyKey.new(
      account: other_account,
      key: "shared-key",
      response_status: 200,
      expires_at: 1.hour.from_now
    )
    assert other.valid?
  end

  test "validates presence of response_status" do
    ik = IdempotencyKey.new(account: @account, key: "test", response_status: nil, expires_at: 1.hour.from_now)
    assert_not ik.valid?
    assert_includes ik.errors[:response_status], "can't be blank"
  end

  test "validates presence of expires_at" do
    ik = IdempotencyKey.new(account: @account, key: "test", response_status: 200, expires_at: nil)
    assert_not ik.valid?
    assert_includes ik.errors[:expires_at], "can't be blank"
  end

  test "active scope returns non-expired keys" do
    active_key = IdempotencyKey.create!(
      account: @account, key: "active", response_status: 200, expires_at: 1.hour.from_now
    )
    _expired_key = IdempotencyKey.create!(
      account: @account, key: "expired", response_status: 200, expires_at: 1.hour.ago
    )

    active_keys = IdempotencyKey.active
    assert_includes active_keys, active_key
    assert_not_includes active_keys, _expired_key
  end

  test "expired scope returns expired keys" do
    _active_key = IdempotencyKey.create!(
      account: @account, key: "active2", response_status: 200, expires_at: 1.hour.from_now
    )
    expired_key = IdempotencyKey.create!(
      account: @account, key: "expired2", response_status: 200, expires_at: 1.hour.ago
    )

    expired_keys = IdempotencyKey.expired
    assert_includes expired_keys, expired_key
    assert_not_includes expired_keys, _active_key
  end

  test "lookup finds active key by account and key" do
    key = IdempotencyKey.create!(
      account: @account, key: "lookup-test", response_status: 201, expires_at: 1.hour.from_now
    )

    found = IdempotencyKey.lookup(account_id: @account.id, key: "lookup-test")
    assert_equal key, found
  end

  test "lookup returns nil for expired keys" do
    IdempotencyKey.create!(
      account: @account, key: "expired-lookup", response_status: 200, expires_at: 1.hour.ago
    )

    found = IdempotencyKey.lookup(account_id: @account.id, key: "expired-lookup")
    assert_nil found
  end

  test "expired? returns true for past expiry" do
    key = IdempotencyKey.new(expires_at: 1.hour.ago)
    assert key.expired?
  end

  test "expired? returns false for future expiry" do
    key = IdempotencyKey.new(expires_at: 1.hour.from_now)
    assert_not key.expired?
  end

  test "TTL constant is 24 hours" do
    assert_equal 24.hours, IdempotencyKey::TTL
  end
end
