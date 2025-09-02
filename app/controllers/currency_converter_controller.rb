class CurrencyConverterController < ApplicationController
  before_action :authenticate_user!

  layout "template"

  def index
    @conversions = current_user.currency_conversions.recent_first.limit(10)
  end

  def get_convert; end

  def convert
    @original_amount = params[:amount].to_f
    @from_currency = params[:from_currency].upcase
    @to_currency = params[:to_currency].upcase

    # Use the wrapper directly for conversion
    api = HexarateApi.new
    @converted_amount = api.convert_currency(@original_amount, @from_currency, @to_currency)

    if @converted_amount
      # Get the current exchange rate
      rate_record = CurrencyRate.find_or_fetch(@from_currency, @to_currency)
      exchange_rate = rate_record&.rate || (@converted_amount / @original_amount)

      # Save the conversion to history
      current_user.currency_conversions.create!(
        from_currency: @from_currency,
        to_currency: @to_currency,
        amount: @original_amount,
        converted_amount: @converted_amount,
        exchange_rate: exchange_rate,
        converted_at: Time.current
      )

      # Reload conversions for the view
      @conversions = current_user.currency_conversions.recent_first.limit(10)

      # redirect to index page of currency_converter
      redirect_to currency_converter_path
    else
      flash.now[:error] = "Unable to convert currency. Please try again."
      @conversions = current_user.currency_conversions.recent_first.limit(10)
      render :index
    end
  end

  def destroy
    @conversion = current_user.currency_conversions.find(params[:id])
    @conversion.destroy
    redirect_to currency_converter_path, notice: "Conversion deleted successfully."
  end

  def clear_history
    current_user.currency_conversions.destroy_all
    redirect_to currency_converter_path, notice: "All conversion history cleared successfully."
  end
end
