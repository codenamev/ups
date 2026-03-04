# frozen_string_literal: true

class ApiTokenIdentifier < ActionMCP::GatewayIdentifier
  identifier :user
  authenticates :api_token

  def resolve
    token = extract_bearer_token
    raise Unauthorized, "API token required" unless token

    api_token = ApiToken.authenticate(token)
    raise Unauthorized, "Invalid API token" unless api_token

    # Set account on the app's Current context
    Current.user = api_token.user
    Current.account = api_token.account

    api_token.user
  end
end

class ApplicationGateway < ActionMCP::Gateway
  identified_by ApiTokenIdentifier
end
