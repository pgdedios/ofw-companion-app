class Package < ApplicationRecord
  belongs_to :user

  validates :tracking_number, presence: true
  validates :courier_name, presence: true
  validates :tracking_number,
            uniqueness: { scope: [ :user_id, :courier_name ],
                          message: "already exists for this user with this courier" }
end
