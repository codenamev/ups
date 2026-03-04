class ApiRequest < ApplicationRecord
  belongs_to :api_token
  has_one :account, through: :api_token
  
  validates :request_path, presence: true
  validates :response_status, numericality: { greater_than: 99, less_than: 600 }
  
  scope :successful, -> { where(response_status: 200..299) }
  scope :failed, -> { where.not(response_status: 200..299) }
  scope :this_month, -> { where(created_at: Time.current.beginning_of_month..Time.current.end_of_month) }
end
