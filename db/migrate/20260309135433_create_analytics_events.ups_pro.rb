# This migration comes from ups_pro (originally 20260220190209)
class CreateAnalyticsEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :analytics_events do |t|
      t.references :user, null: false, foreign_key: true
      t.string :event_type
      t.json :metadata
      t.datetime :occurred_at

      t.timestamps
    end
  end
end
