class AddUniqueIndexOnComponentNamePerStatusPage < ActiveRecord::Migration[8.0]
  def change
    add_index :components, [ :status_page_id, :name ], unique: true, name: "index_components_on_status_page_id_and_name"
  end
end
