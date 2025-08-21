class AddTrackingEventsToPackages < ActiveRecord::Migration[7.2]
  def change
    add_column :packages, :tracking_events, :jsonb, default: [], null: false
  end
end
