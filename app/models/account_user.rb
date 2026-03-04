class AccountUser < ApplicationRecord
  belongs_to :account
  belongs_to :user

  validates :role, inclusion: { in: %w[owner admin member] }
  validates :account_id, uniqueness: { scope: :user_id }
end
