class CurrencyConversion < ApplicationRecord
  belongs_to :user

  validates :from_currency, :to_currency, presence: true, length: { is: 3 }
  validates :amount, :converted_amount, :exchange_rate, presence: true, numericality: { greater_than: 0 }
  validates :converted_at, presence: true

  scope :recent_first, -> { order(converted_at: :desc) }
  scope :by_date, ->(date) { where(converted_at: date.beginning_of_day..date.end_of_day) }
end
