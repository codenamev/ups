class CreateWebhookDeliveries < ActiveRecord::Migration[8.1]
  def change
    create_table :webhook_deliveries do |t|
      t.references :webhook, null: false, foreign_key: true
      t.string :event_type, null: false
      t.text :event_data, null: false
      t.string :idempotency_key, null: false
      t.string :status, null: false, default: "pending"
      t.integer :response_status
      t.text :response_body
      t.datetime :delivered_at
      t.integer :retries, null: false, default: 0
      t.datetime :last_retry_at

      t.timestamps
    end

    add_index :webhook_deliveries, :idempotency_key, unique: true
    add_index :webhook_deliveries, [:webhook_id, :event_type]
    add_index :webhook_deliveries, [:status, :created_at]
  end
end
