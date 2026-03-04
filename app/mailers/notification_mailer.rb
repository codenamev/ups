class NotificationMailer < ApplicationMailer
  def incident_created(subscriber, incident)
    @subscriber = subscriber
    @incident = incident
    @status_page = incident.status_page
    @unsubscribe_url = @subscriber.unsubscribe_url

    mail(
      to: @subscriber.email,
      subject: "[#{@status_page.name}] New Incident: #{@incident.title}"
    )
  end

  def incident_updated(subscriber, incident)
    @subscriber = subscriber
    @incident = incident
    @status_page = incident.status_page
    @unsubscribe_url = @subscriber.unsubscribe_url

    mail(
      to: @subscriber.email,
      subject: "[#{@status_page.name}] Incident Update: #{@incident.title}"
    )
  end

  def incident_resolved(subscriber, incident)
    @subscriber = subscriber
    @incident = incident
    @status_page = incident.status_page
    @unsubscribe_url = @subscriber.unsubscribe_url

    mail(
      to: @subscriber.email,
      subject: "[#{@status_page.name}] Incident Resolved: #{@incident.title}"
    )
  end

  def component_status_change(subscriber, component, old_status)
    @subscriber = subscriber
    @component = component
    @old_status = old_status
    @new_status = component.status
    @status_page = component.status_page
    @unsubscribe_url = @subscriber.unsubscribe_url

    mail(
      to: @subscriber.email,
      subject: "[#{@status_page.name}] #{@component.name} Status Changed"
    )
  end

  private

  def default_url_options
    Rails.application.config.action_mailer.default_url_options
  end
end
