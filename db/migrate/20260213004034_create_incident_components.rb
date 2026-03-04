class CreateIncidentComponents < ActiveRecord::Migration[8.1]
  def change
    create_table :incident_components do |t|
      t.references :incident, null: false, foreign_key: true
      t.references :component, null: false, foreign_key: true

      t.timestamps
    end
  end
end
