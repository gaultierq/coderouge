json.extract! waypoint, :id, :latitude, :longitude, :logbook, :date
json.url waypoint_url(waypoint, format: :json)
json.latitude waypoint.latitude.to_f
json.longitude waypoint.longitude.to_f
json.from_id waypoint.from.try(:id)
json.to_id waypoint.to.try(:id)

