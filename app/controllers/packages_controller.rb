class PackagesController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [ :webhook_update ] # required for external webhook
  before_action :authenticate_user!, except: [ :webhook_update ]
  before_action :set_package, only: [ :show ]

  def index
    @packages = current_user.packages.order(created_at: :desc)
  end

  def new
    @carriers = TrackingService.carriers
    tn = params[:tracking_number]
    carrier = params[:carrier]

    @tracking_details =
      if tn.present?
        TrackingService.new(tn, carrier).track
      else
        []
      end
  end

  def show
    # @package = current_user.packages.find(params[:id])
    @tracking_details = TrackingService.new(@package.tracking_number, @package.courier_name).track
  end

  def create
    @package = current_user.packages.new(
      tracking_number: params[:tracking_number],
      courier_name: params[:courier_name],
      tracking_events: safe_parse_events(params[:tracking_events])
    )

    tracking_details = TrackingService.new(@package.tracking_number, @package.courier_name).track
    @package.status = tracking_details.first[:status] if tracking_details.any?

    if @package.save
      redirect_to packages_path, notice: "Package added."
    else
      flash[:alert] = @package.errors.full_messages.join(", ")
      redirect_to packages_path
    end
  end

  def webhook_update
    data = JSON.parse(request.raw_post) rescue {}
    tracking_number = data["tracking_number"] || data.dig("data", "number")

    service = PackageWebhookService.new(tracking_number, data) # pass payload in

    if service.process
      render json: { success: true }
    else
      render json: { success: false, error: "Package not found or no changes" }, status: :not_found
    end
  end

  private

  def set_package
    @package = current_user.packages.find(params[:id])
  end

  def package_params
    params.permit(:tracking_number, :courier_name, :status, tracking_events: [])
  end

  def safe_parse_events(json_string)
    JSON.parse(json_string) rescue []
  end

  # Merge webhook + existing events (no duplicates, newest first)
  # def merge_tracking_events(existing, incoming)
  #   existing ||= []
  #   incoming ||= []
  #   (existing + incoming)
  #     .uniq { |e| [ e["status"], e["date"] ] }
  #     .sort_by { |e| e["date"] }
  #     .reverse
  # end
end
