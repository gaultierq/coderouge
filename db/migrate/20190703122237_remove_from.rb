class RemoveFrom < ActiveRecord::Migration[5.2]
  def change
    remove_foreign_key :waypoints, column: :from_id
    remove_column :waypoints, :from_id, :integer, null: true, index: true
  end
end
