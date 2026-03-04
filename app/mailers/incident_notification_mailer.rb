class IncidentNotificationMailer < ApplicationMailer
  default from: "noreply@ups.dev"

  def incident_created(subscriber, incident)
    @subscriber = subscriber
    @incident = incident
    @status_page = incident.status_page
    @unsubscribe_url = unsubscribe_url(token: subscriber.unsubscribe_token)

    mail(
      to: subscriber.email,
      subject: "[#{@status_page.name}] New Incident: #{incident.title}",
      template_name: 'incident_created'
    )
  end

  def incident_updated(subscriber, incident, incident_update)
    @subscriber = subscriber
    @incident = incident
    @incident_update = incident_update
    @status_page = incident.status_page
    @unsubscribe_url = unsubscribe_url(token: subscriber.unsubscribe_token)

    mail(
      to: subscriber.email,
      subject: "[#{@status_page.name}] Incident Update: #{incident.title}",
      template_name: 'incident_updated'
    )
  end

  def incident_resolved(subscriber, incident)
    @subscriber = subscriber
    @incident = incident
    @status_page = incident.status_page
    @unsubscribe_url = unsubscribe_url(token: subscriber.unsubscribe_token)

    mail(
      to: subscriber.email,
      subject: "[#{@status_page.name}] Incident Resolved: #{incident.title}",
      template_name: 'incident_resolved'
    )
  end

  private

  def unsubscribe_url(token:)
    Rails.application.routes.url_helpers.unsubscribe_url(token: token, host: Rails.application.config.action_mailer.default_url_options[:host])
  end
end