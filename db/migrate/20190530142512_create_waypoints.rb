class CreateWaypoints < ActiveRecord::Migration[5.2]
  def change
    create_table :waypoints do |t|
      t.decimal :latitude
      t.decimal :longitude
      t.text :logbook
      t.datetime :date

      t.timestamps
    end
  end
end
