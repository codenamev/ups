class CreateSubscribers < ActiveRecord::Migration[8.1]
  def change
    create_table :subscribers do |t|
      t.references :status_page, null: false, foreign_key: true
      t.string :email
      t.datetime :confirmed_at
      t.datetime :unsubscribed_at

      t.timestamps
    end
  end
end
