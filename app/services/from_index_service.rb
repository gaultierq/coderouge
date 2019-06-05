class FromIndexService

  def perform

    ids = Waypoint.order(date: :asc).pluck(:id)

    last = nil
    ids.each do |wid|
      w = Waypoint.find(wid)
      w.from_id = last
      w.save
      last = wid
    end
  end
end