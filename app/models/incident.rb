class Incident < ApplicationRecord
  belongs_to :account
  belongs_to :status_page
  belongs_to :user
  has_many :incident_updates, -> { order(:created_at) }, dependent: :destroy
  has_many :incident_components, dependent: :destroy
  has_many :components, through: :incident_components
  has_many :incident_events, -> { order(:occurred_at) }, dependent: :destroy

  enum :status, {
    investigating: 0,
    identified: 1,
    monitoring: 2,
    resolved: 3
  }, prefix: :status

  enum :impact, {
    minor: 0,
    major: 1,
    critical: 2,
    maintenance: 3
  }, prefix: :impact

  validates :title, presence: true, length: { maximum: 255 }
  validates :description, length: { maximum: 5000 }, allow_blank: true
  validates :status, :impact, presence: true
  validates :started_at, presence: true
  validates :resolved_at, presence: true, if: :status_resolved?
  
  validate :resolved_at_after_started_at

  # Aliases for backward compatibility with tests
  def name
    title
  end

  def shortlink
    "#{status_page.slug}/incidents/#{id}"
  end

  scope :active, -> { where.not(status: :resolved) }
  scope :recent, -> { where(created_at: 30.days.ago..) }

  before_validation :set_started_at, on: :create
  after_update :set_resolved_at, if: :saved_change_to_status?
  after_create :broadcast_new_incident
  after_update :broadcast_incident_update
  after_create :notify_incident_created
  after_update :notify_incident_resolved, if: -> { saved_change_to_status? && status_resolved? }

  private

  def set_started_at
    self.started_at = Time.current if started_at.blank?
  end

  def set_resolved_at
    if status_resolved? && resolved_at.blank?
      self.resolved_at = Time.current
    elsif !status_resolved?
      self.resolved_at = nil
    end
  end

  def broadcast_new_incident
    broadcast_replace_to "status_page_#{status_page.slug}",
                         target: "recent-incidents",
                         partial: "public/status_pages/recent_incidents",
                         locals: { recent_incidents: status_page.incidents.limit(10) }
  end

  def broadcast_incident_update
    return unless saved_change_to_status? || saved_change_to_title? || saved_change_to_description?

    broadcast_replace_to "status_page_#{status_page.slug}",
                         target: "recent-incidents",
                         partial: "public/status_pages/recent_incidents",
                         locals: { recent_incidents: status_page.incidents.limit(10) }
  end

  def notify_incident_created
    NotificationService.notify_incident_created(self)
  end

  def notify_incident_resolved
    NotificationService.notify_incident_resolved(self)
  end
  
  def resolved_at_after_started_at
    return unless started_at.present? && resolved_at.present?
    
    if resolved_at < started_at
      errors.add(:resolved_at, "must be after the incident started")
    end
  end
end
