# Sessions controller for magic link authentication
class SessionsController < ApplicationController
  include MagicLinkAuthentication
  
  skip_before_action :authenticate_user!, only: [ :new, :create, :verify_magic_link ]

  def new
    # Show magic link request form
  end

  def create
    email = params[:email_address]&.strip&.downcase

    if email.present?
      # Register new user or find existing user
      user = UserRegistrationService.register_or_find_user(email)
      email_sent = send_magic_link(user)
      
      if email_sent
        redirect_to new_session_path, notice: "Check your email for a sign-in link"
      else
        redirect_to new_session_path, alert: "We couldn't send the sign-in email. Please try again or contact support."
      end
    else
      redirect_to new_session_path, alert: "Please enter a valid email address"
    end
  end

  def verify_magic_link
    token = params[:token]
    user = User.find_by_magic_link_token(token) if token.present?

    if user
      start_new_session_for(user)
      user.update_last_sign_in!
      
      redirect_to after_authentication_url, notice: "Welcome back!"
    else
      redirect_to new_session_path, alert: "That link is invalid or has expired"
    end
  end

  def destroy
    reset_authentication
    redirect_to new_session_path, notice: "You have been signed out"
  end

  private

  def start_new_session_for(user)
    session[:current_user_id] = user.id
    session[:current_account_id] = user.primary_account&.id
    Current.user = user
    Current.account = user.primary_account
  end

  def after_authentication_url
    return session.delete(:return_to_url) if session[:return_to_url].present?
    
    dashboard_path
  end

  def reset_authentication
    Current.user = nil
    Current.account = nil
    session.delete(:current_user_id)
    session.delete(:current_account_id)
  end
end
