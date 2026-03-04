class AddUniqueIndexToSubscribers < ActiveRecord::Migration[8.1]
  def change
    add_index :subscribers, [ :status_page_id, :email ], unique: true
  end
end
