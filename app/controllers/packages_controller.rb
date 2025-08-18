class PackagesController < ApplicationController
  def index
    tn = params[:tracking_number]
    carrier = params[:carrier]

    @carriers = TrackingService.carriers

    if tn.present?
      # Delegate everything to the service
      @tracking_details = TrackingService.new(tn, carrier).track
    else
      @tracking_details = []
    end
  end
end
