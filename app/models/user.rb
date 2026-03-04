class User < ApplicationRecord
  has_many :account_users, dependent: :destroy
  has_many :accounts, through: :account_users
  has_many :incidents, dependent: :nullify
  has_many :incident_events, dependent: :nullify
  has_many :incident_updates, dependent: :nullify
  has_many :api_tokens, dependent: :destroy

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true

  normalizes :email, with: ->(email) { email.strip.downcase }

  # Rails 8 authentication methods
  generates_token_for :magic_link, expires_in: 15.minutes

  # Class method for magic link authentication
  def self.find_by_magic_link_token(token)
    find_by_token_for(:magic_link, token)
  end

  # Check if user has access to account
  def can_access_account?(account)
    accounts.include?(account)
  end

  # Get role for specific account
  def role_for_account(account)
    account_users.find_by(account: account)&.role || 'member'
  end

  # Check if user is admin for account
  def admin_for?(account)
    role_for_account(account) == 'admin'
  end

  # Get primary account (for single-account users)
  def primary_account
    accounts.first
  end

  # Update last sign in timestamp
  def update_last_sign_in!
    update!(last_sign_in_at: Time.current)
  end
end
