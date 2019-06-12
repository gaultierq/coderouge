class WaypointsController < ApplicationController
  before_action :set_waypoint, only: [:show, :edit, :update, :destroy]

  # GET /waypoints
  # GET /waypoints.json
  def index

    # let it be iframed
    response.headers.delete "X-Frame-Options"

    bounds = params.dig(:bounds)

    if bounds

      json_parse = JSON.parse(bounds)
      south = json_parse["south"]
      west = json_parse["west"]
      east = json_parse["east"]
      north = json_parse["north"]

      # puts "this are the params: #{south}  #{west}  #{north}  #{east}"
      sw = Geokit::LatLng.new(south,west)
      ne = Geokit::LatLng.new(north,east)

      waypoints = Waypoint.in_bounds([sw, ne]).order(date: :desc).to_a

      Rails.logger.info("Waypoints in bounds: #{waypoints}")

      # adding the edges
      @waypoints = waypoints.map {|wp| [wp.to, wp, wp.from]}.reduce([], &:concat).uniq.compact
    else
      @waypoints = Waypoint.order(date: :desc).limit(4)
    end

    respond_to do |format|
      format.html
      format.json { render :index, status: :ok}
    end
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
    respond_to do |format|
      format.html { redirect_to waypoints_url, notice: 'Waypoint was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_waypoint
    @waypoint = Waypoint.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def waypoint_params
    params.require(:waypoint).permit(:latitude, :longitude, :logbook, :date)
  end
end
