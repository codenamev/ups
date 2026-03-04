class DeliverWebhookJob < ApplicationJob
  queue_as :webhooks
  retry_on StandardError, wait: :polynomially_longer, attempts: 3

  def perform(webhook_delivery_id)
    delivery = WebhookDelivery.find(webhook_delivery_id)
    webhook = delivery.webhook

    return if delivery.delivered?
    return unless delivery.can_retry?

    begin
      response = deliver_webhook(webhook, delivery)
      
      if response.code.to_i.between?(200, 299)
        delivery.mark_delivered!(response.code.to_i, response.body)
        Rails.logger.info "Webhook delivered successfully to #{webhook.url} (delivery: #{delivery.id})"
      else
        delivery.mark_failed!(response.code.to_i, response.body)
        Rails.logger.warn "Webhook delivery failed to #{webhook.url} (delivery: #{delivery.id}): HTTP #{response.code}"
        
        # Schedule retry if possible
        schedule_retry(delivery) if delivery.can_retry?
      end
    rescue => e
      delivery.mark_failed!(nil, e.message)
      Rails.logger.error "Webhook delivery error to #{webhook.url} (delivery: #{delivery.id}): #{e.message}"
      
      # Schedule retry if possible
      schedule_retry(delivery) if delivery.can_retry?
    end
  end

  private

  def deliver_webhook(webhook, delivery)
    uri = URI(webhook.url)
    
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'
    http.open_timeout = 10
    http.read_timeout = 30

    request = Net::HTTP::Post.new(uri.path)
    request['Content-Type'] = 'application/json'
    request['User-Agent'] = 'UpsDevWebhook/1.0'
    request['X-Webhook-Signature'] = generate_signature(webhook, delivery.event_data)
    request['X-Webhook-Delivery'] = delivery.idempotency_key
    request['X-Webhook-Event'] = delivery.event_type
    request.body = delivery.event_data

    http.request(request)
  end

  def generate_signature(webhook, payload)
    'sha256=' + OpenSSL::HMAC.hexdigest('sha256', webhook.secret_token, payload)
  end

  def schedule_retry(delivery)
    DeliverWebhookJob.set(wait: delivery.retry_delay).perform_later(delivery.id)
  end
end
