json.extract! stopover, :latitude, :longitude, :start_date, :end_date
json.latitude waypoint.latitude.to_f
json.longitude waypoint.longitude.to_f

