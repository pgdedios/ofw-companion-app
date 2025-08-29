class AddFullPayloadToPackages < ActiveRecord::Migration[7.2]
  def change
    add_column :packages, :full_payload, :jsonb, default: []
  end
end
