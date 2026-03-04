class RemoveAccountIdFromUsers < ActiveRecord::Migration[8.1]
  def change
    # Remove the foreign key first
    remove_foreign_key :users, :accounts, if_exists: true
    
    # Remove the column and index
    remove_index :users, :account_id, if_exists: true
    remove_column :users, :account_id, :integer, if_exists: true
    
    # Remove the role column from users as it belongs in account_users
    remove_column :users, :role, :string, if_exists: true
  end
end
