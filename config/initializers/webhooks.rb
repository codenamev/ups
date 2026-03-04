# Webhook configuration
Rails.application.config.after_initialize do
  # Schedule periodic webhook retry — only in server processes with DB access
  if (Rails.env.production? || Rails.env.staging?) && !Rails.env.test? && defined?(SolidQueue)
    begin
      RetryFailedWebhooksJob.set(wait: 1.minute).perform_later
    rescue => e
      Rails.logger.warn "Could not schedule RetryFailedWebhooksJob: #{e.message}"
    end
  end
end
