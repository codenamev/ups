class CreateMonitorSummaries < ActiveRecord::Migration[8.1]
  def change
    create_table :monitor_summaries do |t|
      t.references :status_monitor, null: false, foreign_key: true
      t.string :period_type
      t.datetime :period_start
      t.integer :checks_count
      t.integer :successful_count
      t.decimal :avg_response_ms
      t.decimal :p95_response_ms
      t.decimal :p99_response_ms
      t.decimal :uptime_percentage

      t.timestamps
    end
  end
end
