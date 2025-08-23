require "net/http"
require "uri"
require "json"

class IprogSmsService
  BASE_URL = "https://sms.iprogtech.com/api/v1/sms_messages"
  def initialize(api_token:)
    @api_token = api_token
  end

  # number should be full E.164 format (e.g., 639109432834)
  def send_sms(number:, message:)
    uri = URI(BASE_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri.path, { "Content-Type" => "application/json" })
    request.body = {
      api_token: @api_token,
      phone_number: number,
      message: message
    }.to_json

    response = http.request(request)
    JSON.parse(response.body)
  rescue => e
    Rails.logger.error("[IprogtechSmsService] Failed to send SMS: #{e.message}")
    false
  end
end
