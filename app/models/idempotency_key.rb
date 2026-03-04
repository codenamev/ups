# frozen_string_literal: true

class IdempotencyKey < ApplicationRecord
  belongs_to :account

  validates :key, presence: true, uniqueness: { scope: :account_id }
  validates :response_status, presence: true
  validates :expires_at, presence: true

  scope :active, -> { where("expires_at > ?", Time.current) }
  scope :expired, -> { where("expires_at <= ?", Time.current) }

  TTL = 24.hours

  def self.lookup(account_id:, key:)
    active.find_by(account_id: account_id, key: key)
  end

  def expired?
    expires_at <= Time.current
  end
end
