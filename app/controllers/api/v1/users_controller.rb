# API controller for user profile
class Api::V1::UsersController < Api::BaseController
  def show
    render_success(
      user: serialize_user(current_user),
      account: serialize_account(current_account)
    )
  end

  private

  def serialize_user(user)
    {
      id: user.id,
      name: user.name,
      email: user.email,
      created_at: user.created_at,
      updated_at: user.updated_at
    }
  end

  def serialize_account(account)
    {
      id: account.id,
      name: account.name,
      slug: account.slug,
      plan: account.effective_plan,
      status_pages_count: account.status_pages_count,
      components_count: account.components_count,
      monitors_count: account.monitors_count,
      team_members_count: account.team_members_count,
      created_at: account.created_at
    }
  end
end