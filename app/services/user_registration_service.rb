# Service to handle new user registration via magic link
class UserRegistrationService
  def self.register_or_find_user(email)
    email = email.strip.downcase
    
    user = User.find_by(email: email)
    
    if user.nil?
      # Create new user and account
      ActiveRecord::Base.transaction do
        user = create_user(email)
        account = create_account_for_user(user)
        create_account_user_relationship(user, account)
        
        Rails.logger.info "New user registered: #{email} with account #{account.slug}"
      end
    end
    
    user
  end
  
  private
  
  def self.create_user(email)
    # Extract name from email (fallback)
    local_part = email.split('@').first
    name = local_part.length > 2 ? local_part.humanize : email
    
    User.create!(
      email: email,
      name: name
    )
  end
  
  def self.create_account_for_user(user)
    # Generate a unique account name based on their name/email
    base_name = user.name.parameterize
    account_name = base_name
    counter = 1
    
    # Ensure uniqueness
    while Account.exists?(slug: account_name.parameterize)
      account_name = "#{base_name}-#{counter}"
      counter += 1
    end
    
    Account.create!(
      name: account_name.humanize,
      slug: account_name.parameterize,
      plan: 'free'
    )
  end
  
  def self.create_account_user_relationship(user, account)
    AccountUser.create!(
      user: user,
      account: account,
      role: 'owner'
    )
  end
end