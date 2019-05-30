class Waypoint < ApplicationRecord

  validates :latitude, presence: true
  validates :longitude, presence: true
  validates :date, presence: true
  validates :date, uniqueness: true
end
