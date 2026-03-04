# API controller for managing API tokens
class Api::V1::ApiTokensController < Api::BaseController
  before_action :set_api_token, only: [ :destroy ]

  def index
    tokens = current_account.api_tokens.includes(:user).order(created_at: :desc)

    render_success(
      api_tokens: tokens.map do |token|
        {
          id: token.id,
          name: token.name,
          masked_token: token.masked_token,
          last_used_at: token.last_used_at,
          user: {
            id: token.user.id,
            name: token.user.name,
            email: token.user.email
          },
          created_at: token.created_at
        }
      end
    )
  end

  def create
    token = current_account.api_tokens.build(token_params)
    token.user = current_user

    if token.save
      render_created(
        api_token: {
          id: token.id,
          name: token.name,
          token: token.full_token, # Only shown once!
          masked_token: token.masked_token,
          created_at: token.created_at
        },
        message: "API token created successfully. Save this token - it won't be shown again!"
      )
    else
      render_validation_errors(ActiveRecord::RecordInvalid.new(token))
    end
  end

  def destroy
    @api_token.destroy!
    render_success(message: "API token deleted successfully")
  end

  private

  def set_api_token
    @api_token = current_account.api_tokens.find(params[:id])
  end

  def token_params
    params.require(:api_token).permit(:name)
  end
end
