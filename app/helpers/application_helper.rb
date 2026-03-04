module ApplicationHelper
  def component_status_color(status)
    case status.to_s
    when "operational"
      "bg-green-500"
    when "degraded_performance"
      "bg-yellow-500"
    when "partial_outage"
      "bg-orange-500"
    when "major_outage"
      "bg-red-500"
    when "maintenance"
      "bg-blue-500"
    else
      "bg-gray-500"
    end
  end

  def status_badge_class(status)
    case status.to_s
    when "operational"
      "bg-green-100 text-green-800"
    when "degraded_performance"
      "bg-yellow-100 text-yellow-800"
    when "partial_outage"
      "bg-orange-100 text-orange-800"
    when "major_outage"
      "bg-red-100 text-red-800"
    when "maintenance"
      "bg-blue-100 text-blue-800"
    else
      "bg-gray-100 text-gray-800"
    end
  end
end
