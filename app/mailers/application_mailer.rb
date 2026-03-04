class ApplicationMailer < ActionMailer::Base
  default from: "ups.dev <notifications@send.codenamev.com>"
  layout "mailer"

  protected

  def status_page_url(status_page)
    Rails.application.routes.url_helpers.public_status_page_url(status_page.slug)
  end
end
