class AddFieldsToIncidents < ActiveRecord::Migration[8.1]
  def change
    add_reference :incidents, :account, null: false, foreign_key: true
    add_column :incidents, :description, :text
  end
end
