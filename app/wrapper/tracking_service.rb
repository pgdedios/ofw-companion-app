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
      events = providers.flat_map { |provider| provider["events"] || [] }

      # Pickup date is simply the earliest timestamp in events
      pickup_event = events.min_by { |e| e["time_iso"] || e["time_utc"] }
      pickup_date = pickup_event&.dig("time_iso") || pickup_event&.dig("time_utc")

      latest = entry.dig("track_info", "latest_event") || {}
      latest_status = entry.dig("track_info", "latest_status") || {}
      time_metrics = entry.dig("track_info", "time_metrics") || {}
      estimated_delivery = time_metrics.dig("estimated_delivery_date", "to")

      provider_info = providers.first&.dig("provider") || {}

      {
        tracking_number: entry["number"],
        carrier_code: entry["carrier"],
        carrier_name: provider_info["name"] || @carrier,
        carrier_alias: provider_info["alias"],
        carrier_tel: provider_info["tel"],
        carrier_homepage: provider_info["homepage"],
        carrier_country: provider_info["country"],
        status: latest_status["status"] || "Unknown",
        stage: latest["stage"] || "Unknown",
        sub_status: latest_status["sub_status"] || latest["sub_status"] || "Unknown",
        origin_country: entry["origin_country"],
        destination_country: entry["destination_country"],
        recipient_phone: entry["phone_number"],
        pickup_date: pickup_date,
        ship_date: entry["ship_date"],
        estimated_delivery: estimated_delivery,
        current_days_in_transit: time_metrics["days_of_transit"],
        total_days_in_transit: time_metrics["days_of_transit_done"],
        events: events
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
