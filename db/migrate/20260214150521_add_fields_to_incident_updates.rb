class AddFieldsToIncidentUpdates < ActiveRecord::Migration[8.1]
  def change
    add_column :incident_updates, :title, :string
    rename_column :incident_updates, :message, :content
  end
end
