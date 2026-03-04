class CreateIncidentUpdates < ActiveRecord::Migration[8.1]
  def change
    create_table :incident_updates do |t|
      t.references :incident, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.text :message
      t.integer :status

      t.timestamps
    end
  end
end
