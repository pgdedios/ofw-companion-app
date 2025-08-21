class ChangeStatusToStringInPackages < ActiveRecord::Migration[7.2]
  def change
    change_column :packages, :status, :string
  end
end
