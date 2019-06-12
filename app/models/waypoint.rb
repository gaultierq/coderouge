class Waypoint < ApplicationRecord
  acts_as_mappable :lat_column_name => :latitude,
                   :lng_column_name => :longitude

  validates :latitude, presence: true
  validates :longitude, presence: true
  validates :date, presence: true
  validates :date, uniqueness: true

  belongs_to :from, :class_name => "Waypoint", foreign_key: 'from_id', optional: true

  def to
    Waypoint.find_by_from_id(self.id)
  end

end
