class Account < ApplicationRecord
  has_many :status_pages, dependent: :destroy
  has_many :account_users, dependent: :destroy
  has_many :users, through: :account_users
  has_many :api_tokens, dependent: :destroy
  has_many :status_monitors, dependent: :destroy
  has_many :components, dependent: :destroy
  has_many :incidents, dependent: :destroy
  has_many :subscribers, dependent: :destroy

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-z0-9\-]+\z/ }
  validates :plan, inclusion: { in: %w[free pro business] }

  after_initialize :set_default_plan, if: :new_record?

  before_validation :set_slug, on: :create

  def status_pages_count
    status_pages.count
  end

  def components_count
    components.count
  end

  def monitors_count
    status_monitors.count
  end

  def team_members_count
    users.count
  end

  def email_notifications_count(period = 30.days)
    # Count emails sent in the current billing period
    subscribers.joins(:notification_preferences)
      .where(last_email_sent_at: period.ago..Time.current)
      .sum(:emails_sent_count)
  end

  def api_requests_count(period = 30.days)
    # TODO: Implement API request tracking
    # This would track requests made with api_tokens belonging to this account
    api_tokens.joins(:api_requests)
      .where(api_requests: { created_at: period.ago..Time.current })
      .count
  rescue NameError
    0 # Return 0 if api_requests tracking isn't implemented yet
  end

  def current_plan
    plan || "free"
  end

  def needs_onboarding?
    !onboarded?
  end

  def mark_as_onboarded!
    update!(onboarded: true)
  end

  private

  def set_slug
    self.slug = name.parameterize if name.present? && slug.blank?
  end

  def set_default_plan
    self.plan ||= "free"
  end
end
