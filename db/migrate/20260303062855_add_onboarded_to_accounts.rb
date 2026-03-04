class AddOnboardedToAccounts < ActiveRecord::Migration[8.1]
  def change
    add_column :accounts, :onboarded, :boolean, default: false, null: false
  end
end
