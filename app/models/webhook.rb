require "resolv"
require "ipaddr"

class Webhook < ApplicationRecord
  belongs_to :account
  belongs_to :status_page
  has_many :webhook_deliveries, dependent: :destroy

  VALID_EVENTS = [
    "incident.created",
    "incident.updated",
    "incident.resolved",
    "component.status_changed",
    "page.overall_status_changed"
  ].freeze

  validates :name, presence: true, length: { maximum: 255 }
  validates :url, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp([ "http", "https" ]) }
  validates :events, presence: true
  validates :secret_token, presence: true

  validate :events_must_be_valid
  validate :validate_not_internal_url

  before_validation :generate_secret_token, on: :create
  before_validation :normalize_events

  scope :active, -> { where(active: true) }

  def event_types
    return [] if events.blank?
    events.split(",").map(&:strip)
  end

  def event_types=(types)
    self.events = Array(types).join(",")
  end

  def subscribes_to?(event_type)
    event_types.include?(event_type.to_s)
  end

  private

  def generate_secret_token
    self.secret_token = SecureRandom.hex(32) if secret_token.blank?
  end

  def normalize_events
    if events.is_a?(Array)
      self.events = events.join(",")
    elsif events.present? && events.start_with?("[")
      parsed = JSON.parse(events)
      self.events = parsed.join(",") if parsed.is_a?(Array)
    end
  rescue JSON::ParserError
    errors.add(:events, "contains invalid JSON")
  end

  PRIVATE_RANGES = [
    IPAddr.new("127.0.0.0/8"),
    IPAddr.new("10.0.0.0/8"),
    IPAddr.new("172.16.0.0/12"),
    IPAddr.new("192.168.0.0/16"),
    IPAddr.new("169.254.0.0/16"),
    IPAddr.new("0.0.0.0/8"),
    IPAddr.new("::1/128"),
    IPAddr.new("fc00::/7")
  ].freeze

  def validate_not_internal_url
    return if url.blank?

    begin
      uri = URI.parse(url)
    rescue URI::InvalidURIError
      return # format validation will catch this
    end

    return if uri.host.blank?

    begin
      addresses = Resolv.getaddresses(uri.host)
    rescue Resolv::ResolvError
      errors.add(:url, "could not be resolved and may point to an internal or private network")
      return
    end

    if addresses.empty?
      errors.add(:url, "could not be resolved and may point to an internal or private network")
      return
    end

    addresses.each do |addr_str|
      begin
        ip = IPAddr.new(addr_str)
      rescue IPAddr::InvalidAddressError
        next
      end

      if PRIVATE_RANGES.any? { |range| range.include?(ip) }
        errors.add(:url, "must not point to an internal or private network address")
        return
      end
    end
  end

  def events_must_be_valid
    return if events.blank?

    invalid_events = event_types - VALID_EVENTS
    if invalid_events.any?
      errors.add(:events, "contains invalid events: #{invalid_events.join(', ')}")
    end
  end
end
