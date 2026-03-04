class StatusPage < ApplicationRecord
  belongs_to :account
  has_many :components, -> { order(:position) }, dependent: :destroy
  has_many :incidents, -> { order(created_at: :desc) }, dependent: :destroy
  has_many :subscribers, dependent: :destroy
  has_many :status_monitors, dependent: :destroy
  has_many :status_updates, through: :components
  has_many :webhooks, dependent: :destroy
  has_one :page_setting, dependent: :destroy
  has_one :branding, dependent: :destroy

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: { scope: :account_id }

  before_validation :set_slug, on: :create
  after_create :create_default_settings

  delegate :timezone, :theme, :custom_css, :maintenance_mode, to: :page_setting, allow_nil: true
  delegate :logo_url, :primary_color, :custom_domain, :favicon_url, to: :branding, allow_nil: true

  private

  def set_slug
    self.slug = name.parameterize if name.present? && slug.blank?
  end

  def create_default_settings
    create_page_setting!(timezone: "UTC", theme: "light")
    create_branding!
  end
end
