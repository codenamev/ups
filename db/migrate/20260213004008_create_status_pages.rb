class CreateStatusPages < ActiveRecord::Migration[8.1]
  def change
    create_table :status_pages do |t|
      t.references :account, null: false, foreign_key: true
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description

      t.timestamps
    end

    add_index :status_pages, [ :account_id, :slug ], unique: true
    add_index :status_pages, :created_at
  end
end
