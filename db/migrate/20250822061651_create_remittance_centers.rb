class CreateRemittanceCenters < ActiveRecord::Migration[7.2]
  def change
    create_table :remittance_centers do |t|
      t.references :user, null: false, foreign_key: true
      t.string :place_id
      t.string :name
      t.string :address

      t.timestamps
    end
  end
end
