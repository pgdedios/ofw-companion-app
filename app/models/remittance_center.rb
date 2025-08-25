class RemittanceCenter < ApplicationRecord
  belongs_to :user
  validates :place_id, uniqueness: { scope: :user_id }
end
