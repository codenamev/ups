require "open3"

class MonitoringOrchestrator
  def initialize(monitor)
    @monitor = monitor
  end

  def perform_check
    start_time = Time.current
    result = execute_check
    duration = ((Time.current - start_time) * 1000).to_i

    changed = status_changed?(result.success?)
    record_summary(result.success?, duration, result.error)

    if changed
      trigger_status_change_workflow(result.success?)
    end

    result
  rescue => error
    Rails.logger.error "Monitor check failed for #{@monitor.name}: #{error.message}"

    # Check before record_summary clears dirty tracking
    changed = status_changed?(false)
    record_summary(false, 0, error.message)
    trigger_status_change_workflow(false) if changed

    OpenStruct.new(
      success?: false,
      error: error.message,
      response_time_ms: 0
    )
  end

  private

  def execute_check
    case @monitor.check_type
    when "http", "https"
      HttpCheckService.new(@monitor).call
    when "tcp"
      TcpCheckService.new(@monitor).call
    when "ping"
      PingCheckService.new(@monitor).call
    else
      raise "Unknown check type: #{@monitor.check_type}"
    end
  end

  def record_summary(success, duration_ms, error = nil)
    # Update monitor last_checked_at
    @monitor.update!(
      last_checked_at: Time.current,
      status: success ? :up : :down
    )

    # Record hourly and daily summaries
    update_summary("hour", Time.current.beginning_of_hour, success, duration_ms)
    update_summary("day", Time.current.beginning_of_day, success, duration_ms)
  end

  def update_summary(period_type, period_start, success, duration_ms)
    summary = @monitor.monitor_summaries.find_or_initialize_by(
      period_type: period_type,
      period_start: period_start
    )

    summary.checks_count = (summary.checks_count || 0) + 1
    summary.successful_count = (summary.successful_count || 0) + (success ? 1 : 0)

    # Update average response time (simple moving average for now)
    if summary.avg_response_ms.present?
      total_response_time = (summary.avg_response_ms * (summary.checks_count - 1)) + duration_ms
      summary.avg_response_ms = (total_response_time / summary.checks_count).round(2)
    else
      summary.avg_response_ms = duration_ms
    end

    # Update percentiles (simplified - for full implementation would need to store all values)
    summary.p95_response_ms = [ summary.p95_response_ms || 0, duration_ms ].max
    summary.p99_response_ms = [ summary.p99_response_ms || 0, duration_ms ].max

    # Calculate uptime percentage
    summary.uptime_percentage = (summary.successful_count.to_f / summary.checks_count * 100).round(2)

    summary.save!
  end

  def status_changed?(current_success)
    previous_status = @monitor.status_was
    new_status = current_success ? "up" : "down"

    previous_status != new_status
  end

  def trigger_status_change_workflow(success)
    new_status = success ? "up" : "down"
    old_status = success ? "down" : "up"

    # Update component status if needed
    component = @monitor.component
    if component.present?
      new_component_status = success ? :operational : determine_failure_status

      unless component.status == new_component_status.to_s
        old_component_status = component.status
        component.update!(status: new_component_status)

        # Trigger notifications for component status change
        NotificationService.notify_component_status_change(component, old_component_status)
      end
    end

    # Auto-create incident for critical failures
    if !success && should_auto_create_incident?
      create_automatic_incident
    end

    # Log status change
    Rails.logger.info "Monitor #{@monitor.name} status changed from #{old_status} to #{new_status}"
  end

  def determine_failure_status
    # Logic to determine appropriate component status based on monitor failure
    # Could be enhanced to consider multiple monitors per component
    :partial_outage
  end

  def should_auto_create_incident?
    # Only auto-create incidents for critical components or repeated failures
    # This would be configurable per monitor/component
    false # Disabled for now, manual incident creation preferred
  end

  def create_automatic_incident
    # This would create an automatic incident for severe monitoring failures
    # Implementation would depend on business rules
    Rails.logger.info "Would create automatic incident for monitor #{@monitor.name} failure"
  end
end

# Supporting service classes for different check types
class HttpCheckService
  def initialize(monitor)
    @monitor = monitor
  end

  def call
    uri = URI.parse(@monitor.url)
    response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", read_timeout: @monitor.timeout_seconds) do |http|
      request = Net::HTTP::Get.new(uri)
      http.request(request)
    end

    success = response.code.to_i == (@monitor.expected_status_code || 200)

    OpenStruct.new(
      success?: success,
      response_time_ms: 0, # Would need to measure actual response time
      status_code: response.code.to_i,
      error: success ? nil : "HTTP #{response.code}: #{response.message}"
    )
  rescue => error
    OpenStruct.new(
      success?: false,
      response_time_ms: 0,
      error: error.message
    )
  end
end

class TcpCheckService
  def initialize(monitor)
    @monitor = monitor
  end

  def call
    uri = URI.parse(@monitor.url)
    start_time = Time.current

    TCPSocket.new(uri.host, uri.port).close
    duration = ((Time.current - start_time) * 1000).to_i

    OpenStruct.new(
      success?: true,
      response_time_ms: duration,
      error: nil
    )
  rescue => error
    OpenStruct.new(
      success?: false,
      response_time_ms: 0,
      error: error.message
    )
  end
end

class PingCheckService
  def initialize(monitor)
    @monitor = monitor
  end

  def call
    uri = URI.parse(@monitor.url)
    host = uri.host

    raise ArgumentError, "Invalid host" if host.blank? || host.match?(/[^a-zA-Z0-9.\-:]/)

    timeout = @monitor.timeout_seconds.to_i.clamp(1, 30)
    stdout, status = Open3.capture2("ping", "-c", "1", "-W", timeout.to_s, host)

    OpenStruct.new(
      success?: status.success?,
      response_time_ms: parse_ping_time(stdout),
      error: status.success? ? nil : "Ping failed"
    )
  rescue => error
    OpenStruct.new(
      success?: false,
      response_time_ms: 0,
      error: error.message
    )
  end

  private

  def parse_ping_time(output)
    if output =~ /time[=<]([\d.]+)\s*ms/
      $1.to_f.round(2)
    else
      0
    end
  end
end
