# Thread-safe attribute storage for current user and account context
class Current < ActiveSupport::CurrentAttributes
  attribute :user, :account

  # Convenience method to check if a user is signed in
  def self.user?
    user.present?
  end

  # Convenience method to check if an account is selected
  def self.account?
    account.present?
  end

  # Reset all current attributes
  def self.reset
    self.user = nil
    self.account = nil
  end
end
