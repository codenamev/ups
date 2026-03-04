class CreateApiRequests < ActiveRecord::Migration[8.1]
  def change
    create_table :api_requests do |t|
      t.references :api_token, null: false, foreign_key: true
      t.string :request_path
      t.integer :response_status

      t.timestamps
    end
    
    add_index :api_requests, :created_at
    add_index :api_requests, [:api_token_id, :created_at]
  end
end
