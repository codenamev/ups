class ApplicationController < ActionController::Base
  # CSRF Protection
  protect_from_forgery with: :exception

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  before_action :set_current_user
  before_action :set_current_account, if: :user_signed_in?
  before_action :authenticate_user!, unless: :public_action?

  protected

  def current_user
    Current.user
  end
  helper_method :current_user

  def current_account
    Current.account
  end
  helper_method :current_account

  def user_signed_in?
    current_user.present?
  end
  helper_method :user_signed_in?

  def authenticate_user!
    unless user_signed_in?
      session[:return_to_url] = request.url if request.get?
      redirect_to new_session_path, alert: "Please sign in to continue"
    end
  end

  def require_account!
    unless current_account
      # For single-tenant users, redirect to dashboard which will set the account
      redirect_to dashboard_path, alert: "Account setup required"
    end
  end

  private

  def set_current_user
    if session[:current_user_id].present?
      Current.user = User.find_by(id: session[:current_user_id])
      if Current.user.nil?
        reset_session
      end
    end
  end

  def set_current_account
    if session[:current_account_id].present?
      account = current_user.accounts.find_by(id: session[:current_account_id])
      Current.account = account if account
    end

    # Fallback to primary account if no account selected
    Current.account ||= current_user.primary_account
  end

  def public_action?
    false # Override in controllers that have public actions
  end
end
