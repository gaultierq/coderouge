json.extract! waypoint, :id, :latitude, :longitude, :logbook, :date, :from_id
json.url waypoint_url(waypoint, format: :json)
json.latitude waypoint.latitude.to_f
json.longitude waypoint.longitude.to_f
json.to waypoint.to.try(:id)

