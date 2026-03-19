class NotificationPreference < ApplicationRecord
  belongs_to :subscriber
  belongs_to :component, optional: true

  validates :subscriber_id, uniqueness: { scope: :component_id }

  # Scopes for different preference types
  scope :global, -> { where(component_id: nil) }
  scope :component_specific, -> { where.not(component_id: nil) }
  scope :for_incident_type, ->(type) { where(type => true) }
  SEVERITY_COLUMNS = {
    "minor" => :severity_minor,
    "major" => :severity_major,
    "critical" => :severity_critical,
    "maintenance" => :severity_maintenance
  }.freeze

  scope :for_severity, ->(severity) {
    column = SEVERITY_COLUMNS[severity.to_s]
    column ? where(column => true) : all
  }

  def self.for_incident(incident, notification_type)
    # Get preferences for subscribers of the incident's status page
    subscriber_ids = incident.status_page.subscribers.active.pluck(:id)

    # Find relevant preferences (global + component-specific)
    global_prefs = global.where(subscriber_id: subscriber_ids, notification_type => true)

    component_ids = incident.component_ids
    result = if component_ids.any?
      component_prefs = component_specific
        .where(component_id: component_ids, subscriber_id: subscriber_ids, notification_type => true)

      global_prefs.or(component_prefs)
    else
      global_prefs
    end

    column = SEVERITY_COLUMNS[incident.impact.to_s]
    column ? result.where(column => true) : result
  end

  def self.for_component_change(component, notification_type = :component_status_change)
    subscriber_ids = component.status_page.subscribers.active.pluck(:id)

    # Global preferences or specific preferences for this component
    global_prefs = global.where(subscriber_id: subscriber_ids, notification_type => true)
    component_prefs = where(component: component, subscriber_id: subscriber_ids, notification_type => true)

    global_prefs.or(component_prefs)
  end
end
