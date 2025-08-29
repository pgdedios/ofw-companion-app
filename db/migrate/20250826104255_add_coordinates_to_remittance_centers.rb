class AddCoordinatesToRemittanceCenters < ActiveRecord::Migration[7.2]
  def change
    add_column :remittance_centers, :latitude, :float
    add_column :remittance_centers, :longitude, :float
  end
end
