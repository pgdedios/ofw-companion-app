class AddCarrierCodeToPackages < ActiveRecord::Migration[7.2]
  def change
    add_column :packages, :carrier_code, :string
  end
end
