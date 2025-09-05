class DashboardController < ApplicationController
  include CurrencyConverterHelper
  before_action :authenticate_user!

  layout "template"

  def index
    @remittance_centers = current_user.remittance_centers.order(created_at: :desc).limit(3)
    @packages = current_user.packages.order(created_at: :desc)
    @in_transit_packages = @packages.in_transit.page(params[:page]).per(5)
    @currency_list = currency_list

    # for weather api
    if @remittance_centers.any?
      center = @remittance_centers.first
      lat = center.latitude
      lon = center.longitude

      service = WeatherApiService.new(ENV["WEATHER_API_KEY"])
      @weather = service.current_weather(lat, lon)
    else
      @weather = {}
    end
  end


  def convert_currency
    begin
      from_currency = params[:from_currency]
      to_currency = params[:to_currency]

      # Validate currencies
      if from_currency.blank? || to_currency.blank?
        render json: { success: false, error: "Please select both currencies" }
        return
      end

      if from_currency == to_currency
        render json: { success: false, error: "Please select different currencies" }
        return
      end

      # Get exchange rate using your existing API wrapper
      hexarate_api = HexarateApi.new
      rate_data = hexarate_api.get_rate(from_currency, to_currency)

      if rate_data && rate_data["data"] && rate_data["data"]["mid"]
        rate = rate_data["data"]["mid"].round(4)

        render json: {
          success: true,
          rate: rate,
          from_currency: from_currency,
          to_currency: to_currency,
          timestamp: Time.current
        }
      else
        render json: {
          success: false,
          error: "Unable to fetch exchange rate. Please try again later."
        }
      end

    rescue StandardError => e
      Rails.logger.error "Currency conversion error: #{e.message}"
      render json: {
        success: false,
        error: "Conversion failed. Please try again."
      }
    end
  end
end
