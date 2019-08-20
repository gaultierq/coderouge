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

  stopovers = StopoverService.new.perform

  puts "stopovers: #{stopovers.map {|so| so.to_s }}"

end

