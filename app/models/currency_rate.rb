class CurrencyRate < ApplicationRecord
  validates :base_currency, :target_currency, :rate, :fetched_at, presence: true
  validates :base_currency, :target_currency, length: { is: 3 }
  validates :rate, numericality: { greater_than: 0 }

  scope :recent, -> { where("fetched_at > ?", 1.hour.ago) }

  def self.find_or_fetch(base_currency, target_currency)
    # Try to find recent cached rate first
    cached_rate = recent.find_by(
      base_currency: base_currency.upcase,
      target_currency: target_currency.upcase
    )

    return cached_rate if cached_rate

    # Fetch from API if no recent cached rate
    api = HexarateApi.new
    rate_data = api.get_rate(base_currency, target_currency)

    if rate_data && rate_data["data"] && rate_data["data"]["mid"]
      create!(
        base_currency: base_currency.upcase,
        target_currency: target_currency.upcase,
        rate: rate_data["data"]["mid"],
        fetched_at: Time.current
      )
    end
  end

  def expired?
    fetched_at < 1.hour.ago
  end
end
