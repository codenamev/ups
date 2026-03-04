class AddFieldsToStatusPages < ActiveRecord::Migration[8.1]
  def change
    add_column :status_pages, :custom_domain, :string
    add_column :status_pages, :published, :boolean, default: true
  end
end
