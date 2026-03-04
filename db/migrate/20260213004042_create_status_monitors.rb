class CreateStatusMonitors < ActiveRecord::Migration[8.1]
  def change
    create_table :status_monitors do |t|
      t.references :status_page, null: false, foreign_key: true
      t.references :component, null: false, foreign_key: true
      t.string :name, null: false
      t.string :url, null: false
      t.integer :check_type, null: false
      t.integer :interval_seconds, default: 300, null: false
      t.integer :timeout_seconds, default: 30, null: false
      t.integer :expected_status_code, default: 200
      t.integer :status, default: 2, null: false
      t.datetime :last_checked_at

      t.timestamps
    end

    add_index :status_monitors, [ :status_page_id, :status ]
    add_index :status_monitors, :last_checked_at
  end
end
