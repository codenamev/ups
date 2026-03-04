class IncidentUpdate < ApplicationRecord
  belongs_to :incident
  belongs_to :user

  validates :title, presence: true
  validates :content, presence: true

  enum :status, {
    investigating: 0,
    identified: 1, 
    monitoring: 2,
    resolved: 3
  }, prefix: :status, allow_nil: true

  scope :recent, -> { order(created_at: :desc) }
  
  after_create :broadcast_new_update, :notify_incident_update
  after_update :broadcast_update_change

  private

  def broadcast_new_update
    return unless incident.status_page&.slug

    broadcast_replace_to "incident_#{incident.id}",
                         target: "incident-updates",
                         partial: "incidents/updates",
                         locals: { incident: incident, incident_updates: incident.incident_updates.recent }
  end

  def broadcast_update_change
    return unless incident.status_page&.slug

    broadcast_replace_to "incident_#{incident.id}",
                         target: "incident-updates", 
                         partial: "incidents/updates",
                         locals: { incident: incident, incident_updates: incident.incident_updates.recent }
  end

  def notify_incident_update
    NotificationService.notify_incident_updated(incident, self)
  end
end
