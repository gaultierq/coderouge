class WaypointsController < ApplicationController

  protect_from_forgery with: :null_session

  before_action :set_waypoint, only: [:show, :edit, :update, :destroy]

  # GET /waypoints
  # GET /waypoints.json
  def index

    # let it be iframed
    response.headers.delete "X-Frame-Options"

    obtain_waypoints

    respond_to do |format|
      format.html
      format.json { render :index, status: :ok}
    end
  end

  def last_position
    @waypoint = Waypoint.order("date").last
    render "waypoints/show.json"
  end

  def polyline
    # let it be iframed
    response.headers.delete "X-Frame-Options"

    bounds = params.dig(:bounds)

    redis_key = "cached_encoded_polyline:#{bounds}"
    encoded = REDIS.get(redis_key) unless bounds.nil?

    if encoded
      Rails.logger.info("cache: encoded polyline hit: " + encoded)
    else
      Rails.logger.info("cache: encoded polyline not found. Constructing...")

      obtain_waypoints
      latlngs = @waypoints.map {|w| [w.latitude, w.longitude]}
      encoded = Polylines::Encoder.encode_points(latlngs)

      REDIS.set(redis_key, encoded)
      Rails.logger.info("polyline input: #{encoded}")
    end

    render plain: encoded

  end

  def infos
    info = {
        total_nm: total_nm,
        last_update: last_update
    }
    render json: info
  end

  def last_update
    Waypoint.order(:date).last.date
  end

  def total_nm
    total = 0
    last_waypoint = nil

    Waypoint.order(:date).each do |w|

      if last_waypoint
        dist = last_waypoint.distance_to(w)
        date_diff = w.date - last_waypoint.date
        raise "order is not good" if date_diff < 0
        current_speed = dist / date_diff * 3600
        # puts "#{w.id} speed: #{current_speed}nm/h"
        if current_speed < 0 || current_speed > 15
          puts "ignoring waypoint=#{w.id}, last wp=#{last_waypoint.id}"
          suspicious = true
        else
          total = total + dist
        end
      end
      last_waypoint = w unless suspicious
    end
    total
  end

  # GET /waypoints/1
  # GET /waypoints/1.json
  def show
  end

  # GET /waypoints/new
  def new
    @waypoint = Waypoint.new
  end

  # GET /waypoints/1/edit
  def edit
  end

  # POST /waypoints
  # POST /waypoints.json
  def create
    @waypoint = Waypoint.new(waypoint_params)
    respond_to do |format|
      if @waypoint.save
        FromIndexService.new.perform
        REDIS.flushall
        format.html { redirect_to @waypoint, notice: 'Waypoint was successfully created.' }
        format.json { render :show, status: :created, location: @waypoint }
      else
        format.html { render :new }
        format.json { render json: @waypoint.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /waypoints/1
  # PATCH/PUT /waypoints/1.json
  def update
    respond_to do |format|
      if @waypoint.update(waypoint_params)
        REDIS.flushall
        format.html { redirect_to @waypoint, notice: 'Waypoint was successfully updated.' }
        format.json { render :show, status: :ok, location: @waypoint }
      else
        format.html { render :edit }
        format.json { render json: @waypoint.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /waypoints/1
  # DELETE /waypoints/1.json
  def destroy
    @waypoint.destroy
    FromIndexService.new.perform
    REDIS.flushall
    respond_to do |format|
      format.html { redirect_to waypoints_url, notice: 'Waypoint was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
  def obtain_waypoints
    bounds = params.dig(:bounds)

    if bounds

      json_parse = JSON.parse(bounds)
      south = json_parse["south"]
      west = json_parse["west"]
      east = json_parse["east"]
      north = json_parse["north"]

      # puts "this are the params: #{south}  #{west}  #{north}  #{east}"
      sw = Geokit::LatLng.new(south, west)
      ne = Geokit::LatLng.new(north, east)

      waypoints = Waypoint.in_bounds([sw, ne]).order(date: :desc).to_a

      Rails.logger.info("Waypoints in bounds: #{waypoints}")

      # adding the edges
      @waypoints = waypoints.map {|wp| [wp.to, wp, wp.from]}.reduce([], &:concat).uniq.compact
    else
      @waypoints = Waypoint.order(date: :desc).limit(4)
    end
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_waypoint
    @waypoint = Waypoint.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def waypoint_params
    params.require(:waypoint).permit(:latitude, :longitude, :logbook, :date)
  end
end
