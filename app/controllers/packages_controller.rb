class PackagesController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [ :webhook_update ] # required for external webhook
  before_action :authenticate_user!, except: [ :webhook_update ]
  before_action :set_package, only: [ :show, :destroy ]
  before_action :set_carriers, only: [ :new, :create ]

  layout "template"

  def index
    @packages = current_user.packages.order(created_at: :desc)
  end

  def new
    tn = params[:tracking_number]
    carrier = params[:carrier]

    @tracking_details =
      if tn.present?
        TrackingService.new(tn, carrier).track
      else
        []
      end
  end

  def show;  end

  def create
    @package = current_user.packages.new(
      tracking_number: params[:tracking_number],
      courier_name: params[:courier_name],
      carrier_code: params[:carrier_code],
      status: params[:status],
      last_location: params[:last_location],
      last_update: params[:last_update],
      expected_delivery: params[:expected_delivery],
      latest_description: params[:latest_description],
      latest_stage: params[:latest_stage],
      latest_substatus: params[:latest_substatus],
      tracking_provider: params[:tracking_provider],
      tracking_events: safe_parse_events(params[:tracking_events]),
      latest_event_raw: safe_parse_events(params[:latest_event_raw]),
      full_payload: safe_parse_events(params[:full_payload])
    )

    if @package.save
      redirect_to packages_path, notice: "Package successfully added."
    else
      @tracking_details = []
      flash.now[:alert] = @package.errors.full_messages.join(", ")
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @package.destroy
    redirect_to packages_path, notice: "Package #{@package.tracking_number} deleted."
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

  def set_carriers
    @carriers = TrackingService.carriers
  end

  def package_params
    params.permit(
      :tracking_number,
      :courier_name,
      :carrier_code,
      :status,
      :sub_status,
      :pickup_date,
      :estimated_delivery,
      :origin_city,
      :origin_state,
      :origin_country,
      :destination_city,
      :destination_state,
      :destination_country,
      tracking_events: [],
      latest_event_raw: [],
      full_payload: []
    )
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
