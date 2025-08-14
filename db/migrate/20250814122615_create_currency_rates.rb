class CreateCurrencyRates < ActiveRecord::Migration[7.2]
  def change
    create_table :currency_rates do |t|
      t.string :base_currency
      t.string :target_currency
      t.decimal :rate
      t.datetime :fetched_at

      t.timestamps
    end
  end
end
