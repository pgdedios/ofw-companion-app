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
    @package = current_user.packages.new(package_params)

    if @package.save
      # Build dynamic message
      message = "Package #{@package.tracking_number} with #{@package.courier_name} is now added. Status: #{@package.status || 'Pending'}"

      # Send new package info to Zapier
      send_to_zapier(@package, message)
      redirect_to packages_path, notice: "Package added."
    else
      flash[:alert] = @package.errors.full_messages.join(", ")
      redirect_to packages_path
    end
  end

  # Webhook endpoint to receive tracking updates
  def webhook_update
    service = TrackingService.new(@package.tracking_number, @package.courier_name)
    tracking_data = service.track.first

    if tracking_data
      # Merge new events intelligently
      @package.merge_tracking_events!(tracking_data[:events])

      # Update latest status
      @package.update(
        status: tracking_data[:status]
      )
    end

    # Build dynamic message for Zapier
    message = "Package #{@package.tracking_number} with #{@package.courier_name} updated. Status: #{@package.status}"

    # Build payload for Zapier
    payload = {
      tracking_number: @package.tracking_number,
      status: @package.status,
      user_email: @package.user.email,
      user_phone: @package.user.contact_number,
      message: message
    }

    # Send to Zapier
    zapier_url = ENV["ZAPIER_WEBHOOK_URL"]
    send_to_zapier_payload(payload, zapier_url) if zapier_url.present?

    render json: { success: true, package: @package }
  end

  private

  def set_package
    @package = current_user.packages.find(params[:id])
  end

  def package_params
    params.permit(:tracking_number, :courier_name, tracking_events: []).tap do |whitelisted|
      whitelisted[:tracking_events] = JSON.parse(params[:tracking_events]) if params[:tracking_events].present?
    end
  end

  # Send package info to Zapier
  def send_to_zapier(package, message)
    payload = {
      tracking_number: package.tracking_number,
      status: package.status,
      user_phone: package.user.contact_number,
      user_email: package.user.email,
      message: message
    }

    zapier_url = ENV["ZAPIER_WEBHOOK_URL"]
    return unless zapier_url.present?

    uri = URI(zapier_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Post.new(uri, "Content-Type" => "application/json")
    request.body = payload.to_json
    http.request(request)
  rescue => e
    Rails.logger.error "Zapier webhook error: #{e.message}"
  end

  # Optional separate method for payload sending
  def send_to_zapier_payload(payload, url)
    uri = URI(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Post.new(uri, "Content-Type" => "application/json")
    request.body = payload.to_json
    http.request(request)
  rescue => e
    Rails.logger.error "Zapier webhook error: #{e.message}"
  end
end
