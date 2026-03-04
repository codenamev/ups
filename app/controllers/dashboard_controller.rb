# Main dashboard controller for authenticated users
class DashboardController < ApplicationController
  before_action :require_account!

  def index
    @status_pages = current_account.status_pages.includes(:components, :incidents)
    @recent_incidents = current_account.incidents.includes(:status_page).recent.limit(5)
    @api_tokens = current_account.api_tokens.includes(:user).limit(3)

    @stats = {
      total_status_pages: @status_pages.count,
      total_components: current_account.components.count,
      active_incidents: current_account.incidents.active.count,
      total_api_tokens: current_account.api_tokens.count
    }
  end
end
