class CreateAccounts < ActiveRecord::Migration[8.1]
  def change
    create_table :accounts do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.string :plan, default: 'free'

      t.timestamps
    end

    add_index :accounts, :slug, unique: true
    add_index :accounts, :created_at
  end
end
