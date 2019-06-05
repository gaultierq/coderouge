class AddFromToWaypoints < ActiveRecord::Migration[5.2]
  def change
    add_column :waypoints, :from_id, :integer, null: true, index: true
    add_foreign_key :waypoints, :waypoints, column: :from_id
  end
end
