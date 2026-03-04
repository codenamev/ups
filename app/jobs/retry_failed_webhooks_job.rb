class RetryFailedWebhooksJob < ApplicationJob
  queue_as :webhooks

  def perform
    Rails.logger.info "Starting webhook retry job"
    
    retried_count = 0
    
    WebhookDelivery.ready_for_retry.find_each do |delivery|
      DeliverWebhookJob.perform_later(delivery.id)
      retried_count += 1
    end
    
    Rails.logger.info "Queued #{retried_count} webhook deliveries for retry"
    
    # Schedule next retry job in 5 minutes
    RetryFailedWebhooksJob.set(wait: 5.minutes).perform_later
  end
end
