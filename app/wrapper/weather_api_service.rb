require "net/http"
require "uri"
require "json"

class WeatherApiService
  BASE_URL = "https://api.weatherapi.com/v1/current.json"

  def initialize(api_key)
    @api_key = api_key
  end

  def current_weather(lat, lon)
    uri = URI(BASE_URL)
    uri.query = URI.encode_www_form(key: @api_key, q: "#{lat},#{lon}")

    response = Net::HTTP.get_response(uri)
    if response.is_a?(Net::HTTPSuccess)
      JSON.parse(response.body)
    else
      Rails.logger.error("Weather API returned non-success: #{response.code}")
      { error: "Failed to fetch weather" }
    end
  rescue => e
    Rails.logger.error("Failed to fetch weather: #{e.message}")
    { error: "Failed to fetch weather" }
  end
end
