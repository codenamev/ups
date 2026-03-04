class CreateIncidentEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :incident_events do |t|
      t.references :incident, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :event_type, null: false
      t.text :data
      t.datetime :occurred_at, null: false

      t.timestamps
    end

    add_index :incident_events, [ :incident_id, :occurred_at ]
    add_index :incident_events, :event_type
  end
end
