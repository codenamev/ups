class Component < ApplicationRecord
  belongs_to :account
  belongs_to :status_page
  has_many :incident_components, dependent: :destroy
  has_many :incidents, through: :incident_components
  has_many :status_monitors, dependent: :destroy
  has_many :status_updates, dependent: :destroy

  enum :status, {
    operational: 0,
    degraded_performance: 1,
    partial_outage: 2,
    major_outage: 3,
    maintenance: 4
  }, prefix: :status

  validates :name, presence: true, length: { maximum: 255 }
  validates :description, length: { maximum: 1000 }, allow_blank: true
  validates :position, presence: true, uniqueness: { scope: :status_page_id }, numericality: { greater_than: 0 }

  scope :visible, -> { where(visible: true) }
  scope :by_position, -> { order(:position) }

  before_validation :set_position, on: :create
  after_update :broadcast_status_update
  after_update :notify_status_change, if: :saved_change_to_status?

  private

  def set_position
    return if position.present?
    self.position = (status_page.components.maximum(:position) || 0) + 1
  end

  def broadcast_status_update
    return unless saved_change_to_status?

    # Calculate old overall status
    old_overall_status = calculate_overall_status_with_old_value

    # Broadcast component update
    broadcast_replace_to "status_page_#{status_page.slug}",
                         target: "component-#{id}",
                         partial: "public/status_pages/component",
                         locals: { component: self }

    # Broadcast overall status update
    overall_status = calculate_overall_status
    broadcast_replace_to "status_page_#{status_page.slug}",
                         target: "overall-status",
                         partial: "public/status_pages/overall_status",
                         locals: { overall_status: overall_status }

    # Notify of overall status change if it changed
    if old_overall_status != overall_status
      WebhookService.deliver_page_overall_status_changed(status_page, old_overall_status, overall_status)
    end
  end

  def calculate_overall_status
    components = status_page.components.visible
    return "operational" if components.empty?

    statuses = components.pluck(:status).uniq

    return "major_outage" if statuses.include?("major_outage")
    return "partial_outage" if statuses.include?("partial_outage")
    return "degraded_performance" if statuses.include?("degraded_performance")
    return "maintenance" if statuses.include?("maintenance")

    "operational"
  end

  def calculate_overall_status_with_old_value
    # Get all visible components except this one, plus this one with old status
    components = status_page.components.visible.where.not(id: id)
    statuses = components.pluck(:status)
    
    # Add the old status of this component
    old_status = status_before_last_save
    statuses << old_status if old_status.present?
    
    return "operational" if statuses.empty?

    statuses = statuses.uniq

    return "major_outage" if statuses.include?("major_outage")
    return "partial_outage" if statuses.include?("partial_outage")
    return "degraded_performance" if statuses.include?("degraded_performance")
    return "maintenance" if statuses.include?("maintenance")

    "operational"
  end

  def notify_status_change
    old_status = status_before_last_save
    NotificationService.notify_component_status_change(self, old_status)
  end
end
