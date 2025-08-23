require "net/http"
require "uri"
require "json"

class SemaphoreSmsService
  BASE_URL = "https://api.semaphore.co/api/v4/messages"

  def initialize(api_key:)
    @api_key = api_key
  end

  # Send SMS
  # number should be in full E.164 format, e.g., 639123456789
  def send_sms(message:, number:)
    uri = URI(BASE_URL)
    req = Net::HTTP::Post.new(uri)
    req["Content-Type"] = "application/json"

    body = {
      apikey: @api_key,
      number: number,
      message: message,
      sendername: "OFWCompanion"
    }
    req.body = body.to_json

    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(req)
    end

    result = JSON.parse(res.body)
    # Returns true if message was accepted
    result["success"] == true
  rescue => e
    Rails.logger.error("[SemaphoreSmsService] Failed to send SMS: #{e.message}")
    false
  end
end
