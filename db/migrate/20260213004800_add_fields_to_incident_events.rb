class AddFieldsToIncidentEvents < ActiveRecord::Migration[8.1]
  def change
    add_column :incident_events, :body, :text
    add_column :incident_events, :previous_status, :string
    add_column :incident_events, :new_status, :string
  end
end
