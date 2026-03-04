Resend.configure do |config|
  config.api_key = Rails.application.credentials.dig(:resend, :api_key)
end