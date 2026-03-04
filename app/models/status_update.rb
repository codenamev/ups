class StatusUpdate < ApplicationRecord
  belongs_to :component
  belongs_to :user
  belongs_to :account

  enum :status, {
    scheduled: 0,
    in_progress: 1,
    completed: 2,
    canceled: 3
  }, prefix: :status

  validates :title, presence: true, length: { maximum: 255 }
  validates :message, presence: true, length: { maximum: 2000 }
  validates :scheduled_for, presence: true
  validates :estimated_duration, presence: true, numericality: { greater_than: 0 }
  validates :status, presence: true
  
  validate :scheduled_for_in_future, on: :create
  validate :estimated_duration_reasonable

  scope :upcoming, -> { where(scheduled_for: Time.current..) }
  scope :active, -> { where(status: [:scheduled, :in_progress]) }
  scope :this_week, -> { where(scheduled_for: Time.current.beginning_of_week..Time.current.end_of_week) }

  after_create :broadcast_new_maintenance
  after_update :broadcast_maintenance_update, if: :saved_change_to_status?
  after_create :notify_maintenance_scheduled
  after_update :notify_maintenance_started, if: -> { saved_change_to_status? && status_in_progress? }
  after_update :notify_maintenance_completed, if: -> { saved_change_to_status? && status_completed? }

  def duration_in_hours
    estimated_duration / 60.0 if estimated_duration
  end

  def estimated_end_time
    scheduled_for + estimated_duration.minutes if scheduled_for && estimated_duration
  end

  def active?
    status_scheduled? || status_in_progress?
  end

  def shortlink
    "#{component.status_page.slug}/maintenance/#{id}"
  end

  private

  def scheduled_for_in_future
    return unless scheduled_for.present?
    
    if scheduled_for <= Time.current
      errors.add(:scheduled_for, "must be in the future")
    end
  end

  def estimated_duration_reasonable
    return unless estimated_duration.present?
    
    # Between 15 minutes and 48 hours
    if estimated_duration < 15 || estimated_duration > 2880
      errors.add(:estimated_duration, "must be between 15 minutes and 48 hours")
    end
  end

  def broadcast_new_maintenance
    return unless component.status_page&.slug

    broadcast_replace_to "status_page_#{component.status_page.slug}",
                         target: "scheduled-maintenance",
                         partial: "public/status_pages/scheduled_maintenance",
                         locals: { maintenance_updates: component.status_page.status_updates.upcoming }
  end

  def broadcast_maintenance_update
    return unless component.status_page&.slug

    broadcast_replace_to "status_page_#{component.status_page.slug}",
                         target: "scheduled-maintenance",
                         partial: "public/status_pages/scheduled_maintenance",
                         locals: { maintenance_updates: component.status_page.status_updates.upcoming }
  end

  def notify_maintenance_scheduled
    NotificationService.notify_maintenance_scheduled(self)
  end

  def notify_maintenance_started
    NotificationService.notify_maintenance_started(self)
  end

  def notify_maintenance_completed
    NotificationService.notify_maintenance_completed(self)
  end
end
