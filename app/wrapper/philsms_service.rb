require "net/http"
require "uri"
require "json"

class PhilsmsService
  API_URL = "https://app.philsms.com/api/v3/sms/send"

  def initialize(api_token: ENV["PHILSMS_API_TOKEN"])
    @api_token = api_token
  end

  def send_sms(recipient:, message:, sender_id: "OFWCompanion", type: "plain")
    normalized = normalize_number(recipient)

    uri = URI.parse(API_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri.request_uri)
    request["Authorization"] = "Bearer #{@api_token}"
    request["Content-Type"] = "application/json"
    request["Accept"] = "application/json"

    request.body = {
      recipient: normalized,
      sender_id: sender_id,
      type: type,
      message: message
    }.to_json

    response = http.request(request)
    JSON.parse(response.body)
  rescue => e
    Rails.logger.error("PhilSMS Error: #{e.message}")
    { "error" => e.message }
  end

  private

  def normalize_number(number)
    number = number.to_s.strip
    return number unless number.start_with?("+63")

    number.sub("+63", "")
  end
end
