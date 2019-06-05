json.extract! waypoint, :id, :latitude, :longitude, :logbook, :date, :from_id
json.url waypoint_url(waypoint, format: :json)
