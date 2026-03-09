# This migration comes from ups_pro (originally 20260302190309)
class AllowNullUsersInAnalyticsEvents < ActiveRecord::Migration[8.1]
  def change
    change_column_null :analytics_events, :user_id, true
  end
end
