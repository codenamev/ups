class AddAccountIdToStatusMonitors < ActiveRecord::Migration[8.1]
  def change
    add_reference :status_monitors, :account, null: false, foreign_key: true
  end
end
