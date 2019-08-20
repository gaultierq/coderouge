class StopoversController < ApplicationController

  protect_from_forgery with: :null_session

  def index

    # let it be iframed
    response.headers.delete "X-Frame-Options"

    @stopovers = StopoverService.new.perform

    respond_to do |format|
      format.json { render :index, status: :ok}
    end
  end

end
