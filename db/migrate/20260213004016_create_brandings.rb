class CreateBrandings < ActiveRecord::Migration[8.1]
  def change
    create_table :brandings do |t|
      t.references :status_page, null: false, foreign_key: true
      t.string :logo_url
      t.string :primary_color
      t.string :custom_domain
      t.string :favicon_url

      t.timestamps
    end
  end
end
