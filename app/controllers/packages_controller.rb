class PackagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_package, only: [ :show, :webhook_update ]

  def index
    @packages = current_user.packages.order(created_at: :desc)
  end

  def new
    @carriers = TrackingService.carriers
    tn = params[:tracking_number]
    carrier = params[:carrier]

    if tn.present?
      @tracking_details = TrackingService.new(tn, carrier).track
    else
      @tracking_details = []
    end
  end

  def show
    @package = current_user.packages.find(params[:id])
    @tracking_details = TrackingService.new(@package.tracking_number, @package.courier_name).track
  end

  def create
    @package = current_user.packages.new(
      tracking_number: params[:tracking_number],
      courier_name: params[:courier_name]
    )

    # Parse tracking_events JSON from hidden field
    @package.tracking_events = JSON.parse(params[:tracking_events]) rescue []

    # Get the official status from TrackingService
    tracking_details = TrackingService.new(@package.tracking_number, @package.courier_name).track
    if tracking_details.any?
      @package.status = tracking_details.first[:status]
    end

    if @package.save
      redirect_to packages_path, notice: "Package added."
    else
      flash[:alert] = @package.errors.full_messages.join(", ")
      redirect_to packages_path
    end
  end

  skip_before_action :verify_authenticity_token, only: [ :webhook_update ] # required for external webhook
  def webhook_update
    payload = request.raw_post
    data = JSON.parse(payload) rescue {}

    tracking_number = data.dig("data", "number")
    events = data.dig("data", "origin_info", "trackinfo") || []

    package = Package.find_by(tracking_number: tracking_number)

    if package
      package.update(
        courier_name: data.dig("data", "carrier_code"),
        tracking_events: merge_tracking_events(package.tracking_events, events)
      )
      render json: { success: true }
    else
      render json: { success: false, error: "Package not found" }, status: :not_found
    end
  end

  private

  def set_package
    @package = current_user.packages.find(params[:id])
  end

  def package_params
    params.permit(:tracking_number, :courier_name, :status, tracking_events: [])
  end

  # merge webhook + existing events (no duplicates)
  def merge_tracking_events(existing, incoming)
    existing ||= []
    incoming ||= []

    combined = (existing + incoming).uniq { |e| [ e["status"], e["date"] ] }
    combined.sort_by { |e| e["date"] }.reverse # newest first
  end
end
