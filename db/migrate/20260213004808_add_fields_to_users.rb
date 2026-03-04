class AddFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_reference :users, :account, null: false, foreign_key: true
    add_column :users, :role, :string, default: "member"
  end
end
