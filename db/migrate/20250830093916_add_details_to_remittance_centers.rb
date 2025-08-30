class AddDetailsToRemittanceCenters < ActiveRecord::Migration[7.2]
  def change
    add_column :remittance_centers, :phone, :string
    add_column :remittance_centers, :rating, :float
    add_column :remittance_centers, :user_ratings_total, :integer
    add_column :remittance_centers, :opening_hours, :text
  end
end
