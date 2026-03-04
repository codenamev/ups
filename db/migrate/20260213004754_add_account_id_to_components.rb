class AddAccountIdToComponents < ActiveRecord::Migration[8.1]
  def change
    add_reference :components, :account, null: false, foreign_key: true
  end
end
