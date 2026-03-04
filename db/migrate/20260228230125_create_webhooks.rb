class CreateWebhooks < ActiveRecord::Migration[8.1]
  def change
    create_table :webhooks do |t|
      t.references :account, null: false, foreign_key: true
      t.references :status_page, null: false, foreign_key: true
      t.string :url, null: false, limit: 2048
      t.text :events, null: false
      t.boolean :active, null: false, default: true
      t.string :secret_token, null: false
      t.string :name, null: false, limit: 255

      t.timestamps
    end

    add_index :webhooks, [:status_page_id, :active]
    add_index :webhooks, :url
  end
end
