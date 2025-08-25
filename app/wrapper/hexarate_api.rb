require "net/http"
require "json"

class HexarateApi
  BASE_URL = "https://hexarate.paikama.co/api/rates/latest"

  def get_rate(base_currency, target_currency)
    uri = URI("#{BASE_URL}/#{base_currency}?target=#{target_currency}")

    response = Net::HTTP.get_response(uri)

    if response.code == "200"
      JSON.parse(response.body)
    else
      Rails.logger.error "Hexarate API Error: #{response.code} - #{response.body}"
      nil
    end
  rescue StandardError => e
    Rails.logger.error "Hexarate API Error: #{e.message}"
    nil
  end

  def convert_currency(amount, from_currency, to_currency)
    rate_data = get_rate(from_currency, to_currency)
    return nil unless rate_data && rate_data["data"] && rate_data["data"]["mid"]

    rate = rate_data["data"]["mid"]
    (amount * rate).round(2)
  end
end
