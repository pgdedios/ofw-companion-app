# app/services/google_places_service.rb
require "net/http"
require "uri"
require "json"

class GooglePlacesService
  BASE_URL = "https://maps.googleapis.com/maps/api/place"

  def initialize(api_key = ENV["GOOGLE_PLACES_API_KEY"])
    @api_key = api_key
  end

  def nearby_search(location:, radius:, keyword: nil, type: nil)
    uri = URI("#{BASE_URL}/nearbysearch/json")
    params = {
      key: @api_key,
      location: location,
      radius: radius,
      keyword: keyword,
      type: type
    }.compact
    uri.query = URI.encode_www_form(params)

    response = Net::HTTP.get(uri)
    JSON.parse(response)
  end
end
