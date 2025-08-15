class CreatePackages < ActiveRecord::Migration[7.2]
  def change
    create_table :packages do |t|
      t.string :tracking_number
      t.string :courier_name
      t.integer :status
      t.string :last_location
      t.datetime :last_update
      t.datetime :expected_delivery
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
