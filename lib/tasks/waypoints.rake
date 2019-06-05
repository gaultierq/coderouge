desc 'Re-index waypoints `froms`'
task :reindex_from => [:environment] do
  FromIndexService.new.perform
end


