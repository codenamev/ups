class AddDeliveryTrackingToSubscribers < ActiveRecord::Migration[8.1]
  def change
    add_column :subscribers, :emails_sent_count, :integer, default: 0
    add_column :subscribers, :last_email_sent_at, :datetime
    add_column :subscribers, :delivery_failures_count, :integer, default: 0
    add_column :subscribers, :last_delivery_failure_at, :datetime
  end
end