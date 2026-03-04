class PagesController < ApplicationController
  layout 'landing', only: [:home]

  def home
    # Redirect authenticated users to their dashboard
    if user_signed_in?
      redirect_to dashboard_path
      return
    end
  end

  private

  def public_action?
    action_name == "home"
  end
end
