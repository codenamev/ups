# Preview all emails at http://localhost:3000/rails/mailers/notification_mailer
class NotificationMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/notification_mailer/incident_created
  def incident_created
    NotificationMailer.incident_created
  end

  # Preview this email at http://localhost:3000/rails/mailers/notification_mailer/incident_updated
  def incident_updated
    NotificationMailer.incident_updated
  end

  # Preview this email at http://localhost:3000/rails/mailers/notification_mailer/incident_resolved
  def incident_resolved
    NotificationMailer.incident_resolved
  end

  # Preview this email at http://localhost:3000/rails/mailers/notification_mailer/component_status_change
  def component_status_change
    NotificationMailer.component_status_change
  end
end
