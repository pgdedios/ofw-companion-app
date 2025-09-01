class ChangeOpeningHoursToJsonbInRemittanceCenters < ActiveRecord::Migration[7.2]
  def change
    change_column :remittance_centers, :opening_hours, :jsonb, using: 'opening_hours::jsonb'
  end
end
