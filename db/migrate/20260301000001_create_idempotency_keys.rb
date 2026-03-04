class CreateIdempotencyKeys < ActiveRecord::Migration[8.1]
  def change
    create_table :idempotency_keys do |t|
      t.string :key, null: false
      t.references :account, null: false, foreign_key: true
      t.integer :response_status, null: false
      t.text :response_body
      t.datetime :expires_at, null: false

      t.timestamps
    end

    add_index :idempotency_keys, [:account_id, :key], unique: true
    add_index :idempotency_keys, :expires_at
  end
end
