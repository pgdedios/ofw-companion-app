require "net/http"
require "uri"
require "json"

class TrackingService
  API_HOST = "api.17track.net"
  API_BASE = "/track/v2.4"
  CARRIERS_URL = "https://res.17track.net/asset/carrier/info/apicarrier.all.json"
  TOKEN    = ENV["PACKAGE_API_KEY"]

  def initialize(tracking_number, carrier = nil)
    @tracking_number = tracking_number
    @carrier = carrier
  end

  # Main method for controller
  def track
    register_tracking
    get_tracking_info
  end

  # Carriers list API (site is adding carriers support every now and then)
  def self.carriers
    uri = URI(CARRIERS_URL)
    response = Net::HTTP.get(uri)
    JSON.parse(response)
  end

  private

  # Step 1: Register the tracking number
  def register_tracking
    payload = [ {
      number: @tracking_number,
      carrier: @carrier.present? ? @carrier.to_i : nil
    } ]

    post("/register", payload)
  end

  # Step 2: Get tracking info
  def get_tracking_info
    payload = [ { number: @tracking_number, carrier: @carrier.present? ? @carrier.to_i : nil } ]
    response = post("/gettrackinfo", payload)
    accepted = response.dig("data", "accepted") || []

    accepted.map do |entry|
      providers = entry.dig("track_info", "tracking", "providers") || []
      tracking_info = entry.dig("track_info")
      events = providers.flat_map { |provider| provider["events"] || [] }
      latest_event = entry.dig("track_info", "latest_event") || {}
      latest_status = entry.dig("track_info", "latest_status") || {}
      time_metrics = entry.dig("track_info", "time_metrics") || {}
      # milestone = entry.dig("track_info", "milestone") || {}
      estimated_delivery = time_metrics.dig("estimated_delivery_date", "to")
      provider_info = providers.first&.dig("provider") || {}

      # Map events with flags
      formatted_events = events.map do |e|
        {
          "time_utc" => e["time_utc"],
          "stage" => (e["stage"].presence || e["sub_status"]&.split("_")&.first),
          "description" => e["description"],
          "location" => e["location"],
          "sms_sent" => false,
          "email_sent" => false
        }
      end

      {
        # carrier info
        tracking_number: entry["number"],
        carrier_code: entry["carrier"],
        carrier_name: provider_info["name"] || @carrier,
        carrier_alias: provider_info["alias"],
        carrier_tel: provider_info["tel"],
        carrier_homepage: provider_info["homepage"],
        carrier_country: provider_info["country"],

        # package status
        status: latest_status["status"] || latest_event["stage"] || "Unknown",
        status_description: latest_event["description"],
        sub_status: latest_status["sub_status"] || latest["sub_status"] || "Unknown",
        origin_country: entry["origin_country"] || tracking_info.dig("shipping_info", "shipper_address", "country"),
        origin_city: entry["origin_city"] || tracking_info.dig("shipping_info", "shipper_address", "city"),
        origin_state: tracking_info.dig("shipping_info", "shipper_address", "state"),
        destination_country: entry["destination_country"] || tracking_info.dig("shipping_info", "recipient_address", "country"),
        destination_city: entry["destination_city"] || tracking_info.dig("shipping_info", "recipient_address", "city"),
        destination_state: tracking_info.dig("shipping_info", "recipient_address", "state"),
        recipient_phone: tracking_info["phone_number"],
        pickup_date: (events.find { |e| e["stage"] == "PickedUp" } || events.last)&.dig("time_utc"),
        ship_date: entry["ship_date"],
        estimated_delivery: estimated_delivery,
        current_days_in_transit: time_metrics["days_of_transit"],

        # events history
        events: formatted_events
      }
    end
  end

  def post(endpoint, payload)
    url = URI("https://#{API_HOST}#{API_BASE}#{endpoint}")
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(url)
    request["17token"] = TOKEN
    request["Content-Type"] = "application/json"
    request.body = payload.to_json

    JSON.parse(http.request(request).body)
  rescue => e
    Rails.logger.error "17Track API error: #{e.message}"
    { "error" => e.message }
  end
end
