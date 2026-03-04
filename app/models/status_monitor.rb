class StatusMonitor < ApplicationRecord
  belongs_to :account
  belongs_to :status_page
  belongs_to :component
  has_many :monitor_summaries, dependent: :destroy

  enum :check_type, { http: 0, https: 1, tcp: 2, ping: 3 }, prefix: :check_type
  enum :status, { up: 0, down: 1, unknown: 2 }, prefix: :status

  validates :name, presence: true, length: { maximum: 255 }
  validates :url, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https tcp]) }
  validates :check_type, presence: true
  validates :interval_seconds, numericality: { greater_than_or_equal_to: 30, less_than_or_equal_to: 86400 } # 30s to 1 day
  validates :timeout_seconds, numericality: { greater_than: 0, less_than: 60 }
  validates :expected_status_code, numericality: { greater_than: 99, less_than: 600 }, if: -> { check_type_http? || check_type_https? }
  
  validate :timeout_less_than_interval

  scope :due_for_check, -> { where("last_checked_at IS NULL OR last_checked_at < ?", Time.current) }
  scope :active, -> { where.not(status: :unknown) }
  
  def due_for_check?
    last_checked_at.nil? || last_checked_at < interval_seconds.seconds.ago
  end
  
  def next_check_at
    return Time.current if last_checked_at.nil?
    last_checked_at + interval_seconds.seconds
  end
  
  private
  
  def timeout_less_than_interval
    return unless timeout_seconds.present? && interval_seconds.present?
    
    if timeout_seconds >= interval_seconds
      errors.add(:timeout_seconds, "must be less than check interval")
    end
  end
end
