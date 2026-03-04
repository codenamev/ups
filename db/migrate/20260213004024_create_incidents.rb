class CreateIncidents < ActiveRecord::Migration[8.1]
  def change
    create_table :incidents do |t|
      t.references :status_page, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.integer :status, default: 0, null: false
      t.integer :impact, default: 0, null: false
      t.datetime :started_at
      t.datetime :resolved_at

      t.timestamps
    end

    add_index :incidents, [ :status_page_id, :status ]
    add_index :incidents, [ :status_page_id, :created_at ]
    add_index :incidents, :started_at
  end
end
