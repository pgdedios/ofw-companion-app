class RemoveDuplicatePackages < ActiveRecord::Migration[7.2]
  def change
    duplicates = Package.group(:user_id, :tracking_number, :courier_name)
                         .having("count(*) > 1")
                         .pluck(:user_id, :tracking_number, :courier_name)

    duplicates.each do |user_id, tracking_number, courier_name|
      Package.where(user_id: user_id, tracking_number: tracking_number, courier_name: courier_name)
             .order(id: :asc)
             .offset(1)
             .destroy_all
    end
  end
end
