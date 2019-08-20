json.extract! stopover, :latitude, :longitude
json.latitude stopover.latitude.to_f
json.longitude stopover.longitude.to_f
json.duration_s  stopover.to_date - stopover.from_date
