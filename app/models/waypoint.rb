class Waypoint < ApplicationRecord
  acts_as_mappable :lat_column_name => :latitude,
                   :lng_column_name => :longitude

  validates :latitude, presence: true
  validates :longitude, presence: true
  validates :date, presence: true
  validates :date, uniqueness: true
end
