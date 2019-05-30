class AddIndexToWaypoints < ActiveRecord::Migration[5.2]
  def change
    add_index :waypoints, :date, unique: true
    change_column_null :waypoints, :latitude, false
    change_column_null :waypoints, :longitude, false
    change_column_null :waypoints, :date, false
  end
end
