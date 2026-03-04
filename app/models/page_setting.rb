class PageSetting < ApplicationRecord
  belongs_to :status_page

  validates :timezone, inclusion: { in: ActiveSupport::TimeZone.all.map(&:name) }
  validates :theme, inclusion: { in: %w[light dark auto] }
end
