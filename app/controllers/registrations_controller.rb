# Registrations controller for new user signup
class RegistrationsController < ApplicationController
  include MagicLinkAuthentication
  
  skip_before_action :authenticate_user!, only: [ :new, :create ]

  def new
    # Show signup form - redirect if already signed in
    redirect_to dashboard_path if user_signed_in?
  end

  def create
    email = params[:email_address]&.strip&.downcase

    return redirect_to(new_registration_path, alert: "Please enter a valid email address") if email.blank?

    Rails.logger.info "Registration attempt for: #{email}"

    case User.find_by(email: email)
    in User => existing_user
      # User exists - redirect to sign in instead
      Rails.logger.info "Existing user signup attempt: #{email}"
      email_sent = send_magic_link(existing_user)
      if email_sent
        redirect_to sign_in_path, notice: "An account with this email already exists. Please check your email for a sign-in link."
      else
        redirect_to sign_in_path, alert: "An account with this email already exists, but we couldn't send the sign-in email. Please try again or contact support."
      end
    in nil
      # Register new user and send magic link
      Rails.logger.info "New user registration: #{email}"
      user = UserRegistrationService.register_or_find_user(email)
      email_sent = send_magic_link(user)
      if email_sent
        redirect_to new_registration_path, notice: "Welcome! Check your email for a secure sign-in link to get started."
      else
        redirect_to new_registration_path, notice: "Welcome! Your account was created, but we couldn't send the welcome email. Please try signing in or contact support."
      end
    end
  rescue StandardError => e
    Rails.logger.error "Registration error for #{email}: #{e.message}"
    redirect_to new_registration_path, alert: "Something went wrong. Please try again."
  end
end