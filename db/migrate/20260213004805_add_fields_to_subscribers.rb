class AddFieldsToSubscribers < ActiveRecord::Migration[8.1]
  def change
    add_reference :subscribers, :account, null: false, foreign_key: true
    add_column :subscribers, :confirmed, :boolean, default: false
    add_column :subscribers, :confirmation_token, :string
  end
end
