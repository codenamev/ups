require "test_helper"

class NotificationMailerTest < ActionMailer::TestCase
  setup do
    @account = accounts(:one)
    @status_page = status_pages(:one)
    @subscriber = subscribers(:one)
    @incident = incidents(:one)
    @component = components(:one)
  end

  test "incident_created email" do
    mail = NotificationMailer.incident_created(@subscriber, @incident)

    assert_equal "[#{@status_page.name}] New Incident: #{@incident.title}", mail.subject
    assert_equal [@subscriber.email], mail.to
    assert_equal ["notifications@send.codenamev.com"], mail.from

    assert_match @incident.title, mail.body.encoded
    assert_match @incident.impact.humanize, mail.body.encoded
    assert_match @subscriber.unsubscribe_url, mail.body.encoded
  end

  test "incident_updated email" do
    mail = NotificationMailer.incident_updated(@subscriber, @incident)

    assert_equal "[#{@status_page.name}] Incident Update: #{@incident.title}", mail.subject
    assert_equal [@subscriber.email], mail.to

    assert_match @incident.title, mail.body.encoded
    assert_match "Incident Update", mail.body.encoded
  end

  test "incident_resolved email" do
    @incident.update!(status: :resolved, resolved_at: Time.current)
    mail = NotificationMailer.incident_resolved(@subscriber, @incident)

    assert_equal "[#{@status_page.name}] Incident Resolved: #{@incident.title}", mail.subject
    assert_equal [@subscriber.email], mail.to

    assert_match @incident.title, mail.body.encoded
    assert_match "Incident Resolved", mail.body.encoded
    assert_match "resolved", mail.body.encoded.downcase
  end

  test "component_status_change email" do
    old_status = "operational"
    mail = NotificationMailer.component_status_change(@subscriber, @component, old_status)

    assert_equal "[#{@status_page.name}] #{@component.name} Status Changed", mail.subject
    assert_equal [@subscriber.email], mail.to

    assert_match @component.name, mail.body.encoded
    assert_match "Status Changed", mail.body.encoded
    assert_match old_status.humanize, mail.body.encoded
  end
end
