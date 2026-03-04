class CreateComponents < ActiveRecord::Migration[8.1]
  def change
    create_table :components do |t|
      t.references :status_page, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.integer :position, null: false
      t.integer :status, default: 0, null: false
      t.boolean :visible, default: true

      t.timestamps
    end

    add_index :components, [ :status_page_id, :position ], unique: true
    add_index :components, :status
  end
end
