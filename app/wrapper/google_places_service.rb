# app/services/google_places_service.rb
require "net/http"
require "uri"
require "json"

class GooglePlacesService
  BASE_URL = "https://maps.googleapis.com/maps/api/place"
  attr_reader :places_api_key

  def initialize(api_key = ENV["GOOGLE_PLACES_API_KEY"])
    raise ArgumentError, "Google Places API key is required" unless api_key.present?
    @places_api_key = api_key
  end

  def nearby_search(location:, radius:, keyword: nil, type: nil)
    endpoint = "nearbysearch/json"
    params = {
      key: @places_api_key,
      location: location,
      radius: radius,
      keyword: keyword,
      type: type
    }.compact

    fetch_json(endpoint, params).fetch(:results, [])
  rescue StandardError => e
    log_error("Nearby Search Error", e)
    []
  end


  def fetch_place_details(place_id)
    endpoint = "details/json"
    params = {
      place_id: place_id,
      fields: "name,formatted_address,international_phone_number,geometry,opening_hours,rating,user_ratings_total",
      key: @places_api_key
    }

    fetch_json(endpoint, params).fetch(:result, {})
  rescue StandardError => e
    log_error("Place Details Error", e)
    {}
  end

  private


  def fetch_json(endpoint, params)
    uri = URI("#{BASE_URL}/#{endpoint}")
    uri.query = URI.encode_www_form(params)

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 2 # seconds
    http.read_timeout = 10 # seconds

    response = http.get(uri.request_uri)

    unless response.is_a?(Net::HTTPSuccess)
      raise "HTTP Error: #{response.code} - #{response.message}"
    end

    JSON.parse(response.body, symbolize_names: true)
  rescue JSON::ParserError => e
    raise "JSON Parsing Error: #{e.message}"
  end


  def log_error(context, error)
    Rails.logger.error("[GooglePlacesService] #{context}: #{error.class} - #{error.message}")
  end
end
