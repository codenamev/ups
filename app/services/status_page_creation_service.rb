require "ostruct"

class StatusPageCreationService
  DEFAULT_PRIMARY_COLOR = "#2563eb"

  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :name, :string
  attribute :slug, :string
  attribute :description, :string
  attribute :account

  validates :name, :account, presence: true
  validates :slug, format: { with: /\A[a-z0-9\-]+\z/ }, allow_blank: true

  def call
    return failure_result unless valid?

    ActiveRecord::Base.transaction do
      status_page = create_status_page
      setup_default_components(status_page)
      setup_default_settings(status_page)
      setup_default_branding(status_page)

      success_result(status_page: status_page)
    end
  rescue => error
    failure_result(error: error.message)
  end

  private

  def create_status_page
    account.status_pages.create!(
      name: name,
      slug: slug || name.parameterize,
      description: description
    )
  end

  def setup_default_components(status_page)
    default_components = [
      { name: "API", description: "Core API services" },
      { name: "Website", description: "Main website and dashboard" },
      { name: "Dashboard", description: "User dashboard and interface" }
    ]

    default_components.each_with_index do |component_data, index|
      status_page.components.create!(
        name: component_data[:name],
        description: component_data[:description],
        position: index + 1,
        status: :operational,
        visible: true,
        account: account
      )
    end
  end

  def setup_default_settings(status_page)
    # PageSetting should be created automatically via after_create callback,
    # but let's ensure it exists with proper defaults
    unless status_page.page_setting
      status_page.create_page_setting!(
        timezone: "UTC",
        theme: "light",
        maintenance_mode: false
      )
    end
  end

  def setup_default_branding(status_page)
    if status_page.branding
      status_page.branding.update!(primary_color: DEFAULT_PRIMARY_COLOR) unless status_page.branding.primary_color.present?
    else
      status_page.create_branding!(primary_color: DEFAULT_PRIMARY_COLOR)
    end
  end

  def success_result(data = {})
    OpenStruct.new(
      success?: true,
      error: nil,
      **data
    )
  end

  def failure_result(error: nil)
    OpenStruct.new(
      success?: false,
      error: error || errors.full_messages.join(", "),
      status_page: nil
    )
  end
end
