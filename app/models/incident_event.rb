class IncidentEvent < ApplicationRecord
  belongs_to :incident
  belongs_to :user

  # Event types for the event sourcing system
  TYPES = %w[
    incident_created
    status_changed
    component_added
    component_removed
    update_posted
    update_edited
    incident_resolved
    reopened
  ].freeze

  validates :event_type, inclusion: { in: TYPES }
  validates :event_type, :occurred_at, presence: true

  scope :chronological, -> { order(:occurred_at, :id) }
  scope :for_incident, ->(incident_id) { where(incident_id: incident_id) }

  before_validation :set_occurred_at, on: :create

  # Serialization for data field
  serialize :data, coder: JSON

  def self.rebuild_incident_state(incident_id)
    events = for_incident(incident_id).chronological

    events.reduce(initial_state) do |state, event|
      apply_event(state, event)
    end
  end

  private

  def set_occurred_at
    self.occurred_at = Time.current if occurred_at.blank?
  end

  def self.initial_state
    {
      status: "investigating",
      impact: "minor",
      component_ids: [],
      updates_count: 0
    }
  end

  def self.apply_event(state, event)
    case event.event_type
    when "incident_created"
      state.merge(event.data.symbolize_keys)
    when "status_changed"
      state.merge(status: event.data["new_status"])
    when "component_added"
      state[:component_ids] << event.data["component_id"]
      state
    when "update_posted"
      state[:updates_count] += 1
      state
    else
      state
    end
  end
end
