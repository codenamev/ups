Resend.configure do |config|
  config.api_key = ENV["RESEND_API_KEY"] || begin
    Rails.application.credentials.dig(:resend, :api_key)
  rescue ActiveSupport::MessageEncryptor::InvalidMessage
    nil
  end
end
