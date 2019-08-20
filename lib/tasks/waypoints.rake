desc 'Re-index waypoints `froms`'
task :reindex_from => [:environment] do
  FromIndexService.new.perform
end

# how to detect a stopover ?
# run over the waypoints, ordered by date
# see the speed between each waypoint
# if speed < x M/h then it is a stop (x = 0,1)
# we take the 2 extremity waypoints, then continue
# as long as < x M/h we add the waypoints
# we give the start/stop date of the stopover
desc 'Stopovers list'
task :stopovers => [:environment] do

  current_speed = nil
  last_waypoint = nil
  current_stopover = nil
  stopovers = []

  Waypoint.order(:date).each do |w|
      suspicious = false

      if last_waypoint
        dist = last_waypoint.distance_to(w)
        date_diff = w.date - last_waypoint.date
        raise "order is not good" if date_diff < 0
        current_speed = dist / date_diff * 3600
        puts "#{w.id} speed: #{current_speed}nm/h"
        if current_speed < 0 || current_speed > 15
          puts "ignoring waypoint=#{w.id}, last wp=#{last_waypoint.id}"
          suspicious = true
        elsif current_speed < 0.2
          current_stopover = [last_waypoint] unless current_stopover
          current_stopover << w
        else
          # navigating
          if current_stopover
            stopovers << current_stopover
            current_stopover = nil
          end
        end
      end
      last_waypoint = w unless suspicious
      # sleep 0.02

  end

  stopovers = stopovers.map do |so|
    center = so.first.midpoint_to(so.last)
    puts "stopovers created from waypoint #{so.map {|w|  "#{w.id},"}}"
    Stopover.new(
        latitude: center.latitude,
        longitude: center.longitude,
        from_date: so.first.date,
        to_date: so.last.date,
    )
  end

  puts "stopovers: #{stopovers.map {|so| so.to_s }}"

end

