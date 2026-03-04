class Branding < ApplicationRecord
  belongs_to :status_page

  validates :primary_color, format: { with: /\A#[0-9a-fA-F]{6}\z/ }, allow_blank: true
  validates :custom_domain, uniqueness: true, allow_blank: true
end
