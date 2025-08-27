class CreateCurrencyConversions < ActiveRecord::Migration[7.2]
  def change
    create_table :currency_conversions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :from_currency
      t.string :to_currency
      t.decimal :amount
      t.decimal :converted_amount
      t.decimal :exchange_rate
      t.datetime :converted_at

      t.timestamps
    end
  end
end
