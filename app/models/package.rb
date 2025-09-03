class Package < ApplicationRecord
  belongs_to :user
  before_validation :set_default_name

  validates :tracking_number, presence: true
  validates :courier_name, presence: true
  validates :tracking_number,
            uniqueness: { scope: [ :user_id, :courier_name ],
                          message: "already exists for this user with this courier" }

  validates :package_name, length: { maximum: 30 }

  # scoping for in_transit_packages
  scope :in_transit, -> {
    where.not("latest_event_raw ->> 'stage' = ? AND latest_event_raw ->> 'sub_status' = ?", "Delivered", "Delivered_Other")
  }

  # ransack
  def self.ransackable_attributes(auth_object = nil)
    %w[
      package_name
      tracking_number
      courier_name
      status
      latest_stage
      latest_substatus
      latest_description
      created_at
      updated_at
    ]
  end

  # Allowlist associations
  def self.ransackable_associations(auth_object = nil)
    %w[user]  # only allow searching by user if needed
  end

  private

  def set_default_name
    if package_name.blank? && courier_name.present?
      self.package_name = "#{courier_name} package"
    end
  end
end
