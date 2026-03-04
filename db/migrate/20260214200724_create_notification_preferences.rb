class CreateNotificationPreferences < ActiveRecord::Migration[8.1]
  def change
    create_table :notification_preferences do |t|
      t.references :subscriber, null: false, foreign_key: true
      t.references :component, null: true, foreign_key: true # Allow null for global preferences
      t.boolean :incident_created, default: true
      t.boolean :incident_updated, default: true
      t.boolean :incident_resolved, default: true
      t.boolean :component_status_change, default: true
      t.boolean :severity_minor, default: true
      t.boolean :severity_major, default: true
      t.boolean :severity_critical, default: true
      t.boolean :severity_maintenance, default: true

      t.timestamps
    end

    add_index :notification_preferences, [:subscriber_id, :component_id], unique: true, name: 'index_notification_preferences_on_subscriber_and_component'
  end
end
