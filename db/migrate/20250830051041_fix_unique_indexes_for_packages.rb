class FixUniqueIndexesForPackages < ActiveRecord::Migration[7.2]
  def change
    remove_index :packages, name: "index_packages_on_user_courier_tracking"

    add_index :packages,
              [ :user_id, :tracking_number, :courier_name ],
              unique: true,
              name: "index_unique_tracking_per_user_and_courier"
  end
end
