# Web interface controller for managing API tokens
class ApiTokensController < ApplicationController
  before_action :require_account!
  before_action :set_api_token, only: [ :show, :destroy ]

  def index
    @api_tokens = current_account.api_tokens.includes(:user).order(created_at: :desc)
  end

  def show
    # Show token details (no token value, that's only shown once on creation)
  end

  def new
    @api_token = current_account.api_tokens.build
  end

  def create
    @api_token = current_account.api_tokens.build(api_token_params)
    @api_token.user = current_user

    if @api_token.save
      # Store the full token in flash to show it once
      flash[:api_token] = {
        name: @api_token.name,
        token: @api_token.full_token,
        message: "API token created successfully! Save this token - it won't be shown again."
      }
      redirect_to api_tokens_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @api_token.destroy!
    redirect_to api_tokens_path, notice: "API token '#{@api_token.name}' was deleted successfully."
  end

  private

  def set_api_token
    @api_token = current_account.api_tokens.find(params[:id])
  end

  def api_token_params
    params.require(:api_token).permit(:name)
  end
end
