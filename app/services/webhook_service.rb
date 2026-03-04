class WebhookService
  include ActiveSupport::Benchmarkable
  
  def self.deliver_incident_created(incident)
    new.deliver_incident_created(incident)
  end

  def self.deliver_incident_updated(incident)
    new.deliver_incident_updated(incident)
  end

  def self.deliver_incident_resolved(incident)
    new.deliver_incident_resolved(incident)
  end

  def self.deliver_component_status_changed(component, old_status)
    new.deliver_component_status_changed(component, old_status)
  end

  def self.deliver_page_overall_status_changed(status_page, old_status, new_status)
    new.deliver_page_overall_status_changed(status_page, old_status, new_status)
  end

  def self.retry_failed_deliveries
    new.retry_failed_deliveries
  end

  def deliver_incident_created(incident)
    deliver_webhooks(
      status_page: incident.status_page,
      event_type: 'incident.created',
      event_data: incident_payload(incident)
    )
  end

  def deliver_incident_updated(incident)
    deliver_webhooks(
      status_page: incident.status_page,
      event_type: 'incident.updated', 
      event_data: incident_payload(incident)
    )
  end

  def deliver_incident_resolved(incident)
    deliver_webhooks(
      status_page: incident.status_page,
      event_type: 'incident.resolved',
      event_data: incident_payload(incident)
    )
  end

  def deliver_component_status_changed(component, old_status)
    deliver_webhooks(
      status_page: component.status_page,
      event_type: 'component.status_changed',
      event_data: component_status_payload(component, old_status)
    )
  end

  def deliver_page_overall_status_changed(status_page, old_status, new_status)
    deliver_webhooks(
      status_page: status_page,
      event_type: 'page.overall_status_changed',
      event_data: page_status_payload(status_page, old_status, new_status)
    )
  end

  def retry_failed_deliveries
    WebhookDelivery.ready_for_retry.includes(:webhook).find_each do |delivery|
      DeliverWebhookJob.perform_later(delivery.id)
    end
  end

  private

  def deliver_webhooks(status_page:, event_type:, event_data:)
    webhooks = status_page.webhooks.active.select { |w| w.subscribes_to?(event_type) }
    
    webhooks.each do |webhook|
      delivery = create_webhook_delivery(webhook, event_type, event_data)
      DeliverWebhookJob.perform_later(delivery.id)
    end
  end

  def create_webhook_delivery(webhook, event_type, event_data)
    webhook.webhook_deliveries.create!(
      event_type: event_type,
      event_data: event_data.to_json,
      idempotency_key: generate_idempotency_key(webhook, event_type, event_data)
    )
  end

  def generate_idempotency_key(webhook, event_type, event_data)
    content = "#{webhook.id}:#{event_type}:#{event_data.to_json}"
    Digest::SHA256.hexdigest(content)[0..31]
  end

  def incident_payload(incident)
    {
      event: {
        id: incident.id,
        type: 'incident',
        occurred_at: incident.started_at.iso8601
      },
      incident: {
        id: incident.id,
        title: incident.title,
        description: incident.description,
        status: incident.status,
        impact: incident.impact,
        started_at: incident.started_at.iso8601,
        resolved_at: incident.resolved_at&.iso8601,
        shortlink: incident.shortlink,
        component_ids: incident.component_ids
      },
      status_page: {
        id: incident.status_page.id,
        name: incident.status_page.name,
        slug: incident.status_page.slug
      }
    }
  end

  def component_status_payload(component, old_status)
    {
      event: {
        id: SecureRandom.uuid,
        type: 'component_status_change',
        occurred_at: Time.current.iso8601
      },
      component: {
        id: component.id,
        name: component.name,
        description: component.description,
        status: component.status,
        previous_status: old_status,
        position: component.position
      },
      status_page: {
        id: component.status_page.id,
        name: component.status_page.name,
        slug: component.status_page.slug
      }
    }
  end

  def page_status_payload(status_page, old_status, new_status)
    {
      event: {
        id: SecureRandom.uuid,
        type: 'page_overall_status_change',
        occurred_at: Time.current.iso8601
      },
      status_page: {
        id: status_page.id,
        name: status_page.name,
        slug: status_page.slug,
        overall_status: new_status,
        previous_overall_status: old_status
      },
      components: status_page.components.visible.map do |component|
        {
          id: component.id,
          name: component.name,
          status: component.status,
          position: component.position
        }
      end
    }
  end

  def logger
    Rails.logger
  end

  def benchmark(message)
    super(message, level: :info) { yield }
  end
end