class CreateStatusUpdates < ActiveRecord::Migration[8.1]
  def change
    create_table :status_updates do |t|
      t.string :title, null: false
      t.text :message, null: false
      t.datetime :scheduled_for, null: false
      t.integer :estimated_duration # in minutes
      t.integer :status, null: false, default: 0
      t.references :component, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :account, null: false, foreign_key: true

      t.timestamps
    end
    
    add_index :status_updates, [:component_id, :scheduled_for]
    add_index :status_updates, [:account_id, :status]
    add_index :status_updates, :scheduled_for
  end
end
