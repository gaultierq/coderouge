class StopoverService


  def perform
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
        # puts "#{w.id} speed: #{current_speed}nm/h"
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

    stopovers.map do |so|
      center = so.first.midpoint_to(so.last)
      puts "stopovers created from waypoint #{so.map {|w|  "#{w.id},"}}"
      nil if (so.last.date - so.first.date)  < 1.day

      Stopover.new(
          latitude: center.latitude,
          longitude: center.longitude,
          from_date: so.first.date,
          to_date: so.last.date,
          )
    end.compact
  end
end