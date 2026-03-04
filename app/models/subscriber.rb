class Subscriber < ApplicationRecord
  belongs_to :account
  belongs_to :status_page
  has_many :notification_preferences, dependent: :destroy

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :email, uniqueness: { scope: :status_page_id }

  scope :confirmed, -> { where(confirmed: true) }
  scope :unconfirmed, -> { where(confirmed: false) }
  scope :subscribed, -> { where(unsubscribed_at: nil) }
  scope :active, -> { confirmed.subscribed }

  before_create :generate_confirmation_token
  before_create :generate_unsubscribe_token
  after_create :create_default_notification_preferences

  def unsubscribe_url
    Rails.application.routes.url_helpers.unsubscribe_url(token: unsubscribe_token)
  end

  def preferences_for(component = nil)
    notification_preferences.find_by(component: component) || 
      build_default_preference(component)
  end

  private

  def generate_confirmation_token
    self.confirmation_token = SecureRandom.urlsafe_base64(32) if confirmation_token.blank?
  end

  def generate_unsubscribe_token
    self.unsubscribe_token = SecureRandom.urlsafe_base64(32) if unsubscribe_token.blank?
  end

  def create_default_notification_preferences
    # Create global notification preference with defaults
    notification_preferences.create!
  end

  def build_default_preference(component = nil)
    notification_preferences.build(component: component)
  end
end
