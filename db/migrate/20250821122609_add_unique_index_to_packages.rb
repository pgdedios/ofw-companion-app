class AddUniqueIndexToPackages < ActiveRecord::Migration[7.2]
  def change
    add_index :packages, [ :user_id, :courier_name, :tracking_number ], unique: true, name: "index_packages_on_user_courier_tracking"
  end
end
