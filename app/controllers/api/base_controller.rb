# Base controller for API endpoints with token authentication
class Api::BaseController < ActionController::API
  before_action :authenticate_api_token!
  before_action :set_current_account
  before_action :rate_limit_api_requests!

  before_action :check_idempotency_key, only: [:create, :update]
  after_action :store_idempotency_key, only: [:create, :update]

  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  rescue_from ActiveRecord::RecordInvalid, with: :render_validation_errors
  rescue_from ActionController::ParameterMissing, with: :render_parameter_missing

  protected

  def current_api_token
    @current_api_token
  end

  def current_user
    @current_user
  end

  def current_account
    @current_account
  end

  private

  def authenticate_api_token!
    token = extract_api_token

    unless token
      render_unauthorized("API token required")
      return
    end

    @current_api_token = ApiToken.authenticate(token)

    unless @current_api_token
      render_unauthorized("Invalid API token")
      return
    end

    @current_user = @current_api_token.user
    @current_account = @current_api_token.account
  end

  def extract_api_token
    # Try Authorization header first: "Bearer ups_live_abc123_xyz789"
    if request.headers["Authorization"]&.start_with?("Bearer ")
      return request.headers["Authorization"].split(" ", 2).last
    end

    # Fallback to query parameter (less secure, but sometimes necessary)
    params[:api_token]
  end

  def set_current_account
    Current.user = current_user
    Current.account = current_account
  end

  def render_unauthorized(message = "Unauthorized")
    render json: { error: message }, status: :unauthorized
  end

  def render_not_found(exception = nil)
    render json: {
      error: {
        code: "not_found",
        message: "Resource not found"
      }
    }, status: :not_found
  end

  def render_validation_errors(exception)
    render json: {
      error: {
        code: "validation_failed",
        message: exception.record.errors.full_messages.join(", "),
        details: exception.record.errors.to_hash
      }
    }, status: :unprocessable_entity
  end

  def render_parameter_missing(exception)
    render json: {
      error: {
        code: "parameter_missing",
        message: "Required parameter missing: #{exception.param}"
      }
    }, status: :bad_request
  end

  def render_success(data, status: :ok)
    render json: data, status: status
  end

  def render_created(data)
    render_success(data, status: :created)
  end

  def render_error(message, status: :bad_request)
    render json: { error: message }, status: status
  end

  # --- Idempotency Key support ---

  def check_idempotency_key
    key = request.headers["Idempotency-Key"]
    return unless key

    cached = IdempotencyKey.lookup(account_id: current_account&.id, key: key)
    if cached
      render json: JSON.parse(cached.response_body), status: cached.response_status
    end
  end

  def store_idempotency_key
    key = request.headers["Idempotency-Key"]
    return unless key && current_account && response.successful?

    IdempotencyKey.create!(
      account: current_account,
      key: key,
      response_status: response.status,
      response_body: response.body,
      expires_at: IdempotencyKey::TTL.from_now
    )
  rescue ActiveRecord::RecordNotUnique
    # Already stored (race condition) — ignore
  end

  def rate_limit_api_requests!
    return unless current_api_token

    cache_key = "api_rate_limit:#{current_api_token.id}:#{Time.current.strftime('%Y%m%d%H%M')}"
    request_count = Rails.cache.read(cache_key).to_i

    # Rate limit: 60 requests per minute per token
    if request_count >= 60
      render json: {
        error: "Rate limit exceeded. Maximum 60 requests per minute per API token.",
        retry_after: 60 - Time.current.sec
      }, status: :too_many_requests
      return
    end

    # Increment counter
    Rails.cache.write(cache_key, request_count + 1, expires_in: 1.minute)

    # Log API request for analytics
    log_api_request
  end

  def log_api_request
    return unless current_api_token

    # Create API request record for tracking (fire and forget)
    begin
      current_api_token.api_requests.create!(
        request_path: "#{request.method} #{request.path}",
        response_status: 200 # Default to 200, will be updated if needed
      )
    rescue => e
      # Don't fail the request if logging fails
      Rails.logger.error "Failed to log API request: #{e.message}"
    end
  end
end
