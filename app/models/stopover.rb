class Stopover
  include ActiveModel::Model

  attr_accessor :latitude, :longitude, :from_date, :to_date
  validates :latitude, :longitude, :from_date, :to_date, presence: true

  def to_s
    "Stopover=[#{'%.4f' % self.latitude},#{'%.5f' % self.longitude} for #{ '%.2f' % ((self.to_date - self.from_date) / 1.day) }d]"
  end


end
