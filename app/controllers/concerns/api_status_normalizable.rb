module ApiStatusNormalizable
  extend ActiveSupport::Concern

  private

  def normalize_status_for_api(status)
    # Map internal status values to API standard values
    case status
    when "maintenance"
      "under_maintenance"
    else
      status
    end
  end

  def normalize_status_from_api(status)
    # Map API status values to internal values
    case status
    when "under_maintenance"
      "maintenance"
    else
      status
    end
  end

  def calculate_uptime_percentage(component)
    # Simplified uptime calculation - in a real system you'd calculate based on incidents/downtime
    # For now, return a static percentage based on status
    case component.status
    when "operational"
      100.0
    when "degraded_performance"
      85.0
    when "partial_outage"
      60.0
    when "major_outage"
      0.0
    when "maintenance"
      95.0
    else
      100.0
    end
  end

  def serialize_component(component)
    {
      id: component.id,
      name: component.name,
      description: component.description,
      status: normalize_status_for_api(component.status),
      status_text: component.status.humanize,
      position: component.position,
      visible: component.visible,
      uptime_percentage: calculate_uptime_percentage(component),
      last_updated_at: component.updated_at,
      created_at: component.created_at
    }
  end
end
