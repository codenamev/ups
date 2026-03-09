# This migration comes from ups_pro (originally 20260216150325)
class CreateSubscriptions < ActiveRecord::Migration[8.1]
  def change
    create_table :subscriptions do |t|
      t.references :account, null: false, foreign_key: true
      t.string :stripe_subscription_id
      t.string :stripe_customer_id
      t.string :plan
      t.string :status
      t.datetime :current_period_start
      t.datetime :current_period_end
      t.datetime :canceled_at

      t.timestamps
    end
  end
end
