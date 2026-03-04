class CreatePageSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :page_settings do |t|
      t.references :status_page, null: false, foreign_key: true
      t.string :timezone
      t.string :theme
      t.text :custom_css
      t.boolean :maintenance_mode

      t.timestamps
    end
  end
end
