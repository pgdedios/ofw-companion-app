class CurrencyConverterController < ApplicationController
  before_action :authenticate_user!

  def index; end

  def convert
    @original_amount = params[:amount].to_f
    @from_currency = params[:from_currency].upcase
    @to_currency = params[:to_currency].upcase

    # Use the wrapper directly for conversion
    api = HexarateApi.new
    @converted_amount = api.convert_currency(@original_amount, @from_currency, @to_currency)

    if @converted_amount
      # Optionally save the rate to database for caching
      CurrencyRate.find_or_fetch(@from_currency, @to_currency)

      # Render the index page with results instead of separate page
      render :index
    else
      flash.now[:error] = "Unable to convert currency. Please try again."
      render :index
    end
  end
end
