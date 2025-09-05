class PackagesController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [ :webhook_update ] # required for external webhook
  before_action :authenticate_user!, except: [ :webhook_update ]
  before_action :set_package, except: [ :index, :new, :create, :webhook_update ]
  before_action :set_carriers, only: [ :new, :create ]
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  layout "template"

  def index
    @q = current_user.packages.ransack(params[:q])
    @packages = @q.result(distinct: true).order(created_at: :desc).page(params[:page]).per(10)
  end

  def new
    @package = Package.new
    tn = params[:tracking_number]
    carrier = params[:carrier]

    if tn.present?
      @tracking_details = TrackingService.new(tn, carrier).track
      if @tracking_details.blank?
        flash.now[:alert] = "No tracking details found. Please check the tracking number and/or add the courier code."
        @tracking_details = []
      end
    else
      @tracking_details = []
    end
  end

  def show; end

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
      full_payload: safe_parse_events(params[:full_payload]),
      package_name: params[:package_name]
    )

    if @package.save
      redirect_to packages_path, notice: "Package successfully added."
    else
      @tracking_details = []
      flash.now[:alert] = @package.errors.full_messages.join(", ")
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @package.update(package_params.slice(:package_name))
      redirect_to package_path(@package), notice: "Package name updated"
    else
      flash.now[:alert] = "Failed to update package name."
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @package.destroy
    redirect_to packages_path, notice: "Package #{@package.tracking_number} deleted."
  end

  def webhook_update
    data = JSON.parse(request.raw_post) rescue {}
    tracking_number = data.dig("data", "number")

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
    params.require(:package).permit(
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
      :package_name,
      tracking_events: [],
      latest_event_raw: [],
      full_payload: []
    )
  end

  def record_not_found
    redirect_to packages_path, alert: "Record does not exist."
  end

  def safe_parse_events(json_string)
    JSON.parse(json_string) rescue []
  end
end
