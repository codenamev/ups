class WebhookDelivery < ApplicationRecord
  belongs_to :webhook

  MAX_RETRIES = 5
  RETRY_DELAYS = [1.minute, 5.minutes, 30.minutes, 2.hours, 12.hours].freeze

  enum :status, {
    pending: 'pending',
    delivered: 'delivered', 
    failed: 'failed',
    retrying: 'retrying'
  }

  validates :event_type, presence: true
  validates :event_data, presence: true
  validates :idempotency_key, presence: true, uniqueness: true

  scope :failed_retries, -> { where(status: ['failed', 'retrying']).where('retries < ?', MAX_RETRIES) }
  scope :ready_for_retry, -> { failed_retries.where('last_retry_at IS NULL OR last_retry_at < ?', 5.minutes.ago) }

  before_validation :generate_idempotency_key, on: :create

  def can_retry?
    retries < MAX_RETRIES && (failed? || retrying?)
  end

  def next_retry_at
    return nil unless can_retry?
    return Time.current if last_retry_at.nil?
    
    delay = RETRY_DELAYS[retries] || RETRY_DELAYS.last
    last_retry_at + delay
  end

  def retry_delay
    RETRY_DELAYS[retries] || RETRY_DELAYS.last
  end

  def mark_delivered!(response_status, response_body = nil)
    update!(
      status: 'delivered',
      delivered_at: Time.current,
      response_status: response_status,
      response_body: response_body&.truncate(10_000)
    )
  end

  def mark_failed!(response_status = nil, response_body = nil)
    increment!(:retries)
    update!(
      status: can_retry? ? 'retrying' : 'failed',
      last_retry_at: Time.current,
      response_status: response_status,
      response_body: response_body&.truncate(10_000)
    )
  end

  def parsed_event_data
    @parsed_event_data ||= JSON.parse(event_data)
  end

  private

  def generate_idempotency_key
    self.idempotency_key = SecureRandom.hex(16) if idempotency_key.blank?
  end
end
