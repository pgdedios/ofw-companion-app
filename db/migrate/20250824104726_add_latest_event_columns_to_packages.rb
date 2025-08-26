class AddLatestEventColumnsToPackages < ActiveRecord::Migration[7.2]
  def change
    add_column :packages, :latest_description, :string
    add_column :packages, :latest_stage, :string
    add_column :packages, :latest_substatus, :string
    add_column :packages, :latest_event_raw, :jsonb
    add_column :packages, :tracking_provider, :string
  end
end
