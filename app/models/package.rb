class Package < ApplicationRecord
  belongs_to :user

  validates :tracking_number, presence: true
  validates :tracking_number, presence: true

  validates :tracking_number,
            uniqueness: {
              scope: :user_id,
              message: "already exists for this user without courier"
            },
            if: -> { courier_name.blank? }

  validates :tracking_number,
            uniqueness: {
              scope: [ :user_id, :courier_name ],
              message: "already exists for this user with this courier"
            },
            unless: -> { courier_name.blank? }
  validates :courier_name, presence: true

  # to merge new events in old events json
  def merge_tracking_events!(new_events)
    self.tracking_events ||= []

    # Merge old and new events
    merged = (self.tracking_events + new_events).uniq { |e| [ e["stage"], e["time_utc"] ] }
    self.tracking_events = merged

    # Set status to latest stage or leave it unchanged if none
    latest_event = merged.max_by { |e| e["time_utc"] }
    self.status = latest_event["stage"] || self.status

    save!(validate: false)  # bypass validation to ensure merge always saves
  end
end
