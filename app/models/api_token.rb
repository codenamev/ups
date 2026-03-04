class ApiToken < ApplicationRecord
  belongs_to :account
  belongs_to :user
  has_many :api_requests, dependent: :destroy

  validates :name, presence: true
  validates :token_prefix, presence: true, uniqueness: true
  validates :token_digest, presence: true

  before_create :generate_token_digest

  def self.authenticate(token)
    return nil unless token.present?

    prefix = token.split("_")[0..2].join("_") # e.g., "ups_live" or "ups_test"
    suffix = token.split("_")[3] # The actual token part

    find_by(token_prefix: prefix)&.then do |api_token|
      if ActiveSupport::SecurityUtils.secure_compare(
        api_token.token_digest,
        Digest::SHA256.hexdigest(suffix)
      )
        api_token.update!(last_used_at: Time.current)
        api_token
      end
    end
  end

  def regenerate_token!
    generate_token_digest
    if save!
      @full_token
    end
  end

  def masked_token
    "#{token_prefix}_****"
  end

  private

  def generate_token_digest
    prefix = "ups_#{Rails.env.production? ? 'live' : 'test'}"
    suffix = SecureRandom.hex(32)

    self.token_prefix = "#{prefix}_#{SecureRandom.hex(4)}"
    self.token_digest = Digest::SHA256.hexdigest(suffix)

    # Return full token once (never stored)
    @full_token = "#{token_prefix}_#{suffix}"
  end

  def full_token
    @full_token
  end
end
