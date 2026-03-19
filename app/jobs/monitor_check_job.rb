class MonitorCheckJob < ApplicationJob
  queue_as :monitors

  retry_on StandardError, wait: :exponentially_longer, attempts: 3

  def perform(monitor_id)
    monitor = StatusMonitor.find(monitor_id)
    MonitoringOrchestrator.new(monitor).perform_check
  rescue ActiveRecord::RecordNotFound
    Rails.logger.warn "Monitor #{monitor_id} not found, skipping check"
    # Don't retry for missing records
  rescue => error
    Rails.logger.error "Monitor check failed for #{monitor_id}: #{error.message}"
    raise error
  end
end
