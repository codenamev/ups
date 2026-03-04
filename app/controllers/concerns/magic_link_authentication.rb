# Concern for handling magic link authentication across controllers
module MagicLinkAuthentication
  extend ActiveSupport::Concern

  private

  def send_magic_link(user)
    return false unless user.present?
    
    token = user.generate_token_for(:magic_link)
    SessionMailer.with(user: user, token: token).magic_link.deliver_later
    
    Rails.logger.info "Magic link sent to user: #{user.email}"
    true
  rescue StandardError => e
    Rails.logger.error "Failed to send magic link to #{user.email}: #{e.message}"
    false
  end
end