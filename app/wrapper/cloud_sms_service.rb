require "net/http"
require "uri"
require "json"
require "base64"

class CloudSmsService
  BASE_URL = "https://api.cloudsms.io/v1/messages"

  def initialize(app_key:, app_secret:)
    credentials = "#{app_key}:#{app_secret}"
    @auth_header = "Basic " + Base64.strict_encode64(credentials)
  end

  # phone_number: E.164 format (e.g., +639171234567)
  def send_sms(number:, message:)
    formatted_number = normalize_number(number)

    uri = URI(BASE_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri.path, {
      "Content-Type"  => "application/json",
      "Authorization" => @auth_header
    })

    request.body = {
      destination: formatted_number,
      message: message,
      type: "sms"
    }.to_json

    response = http.request(request)

    Rails.logger.info("[CloudSmsService] HTTP #{response.code}")
    Rails.logger.info("[CloudSmsService] Body: #{response.body}")

    JSON.parse(response.body)
  rescue => e
    Rails.logger.error("[CloudSmsService] Failed to send SMS: #{e.message}")
    false
  end

  private

  # Normalize E.164 to what CloudSMS expects
  def normalize_number(number)
    number = number.to_s.strip
    return number unless number.start_with?("+63")

    number.sub("+63", "0")
  end
end
