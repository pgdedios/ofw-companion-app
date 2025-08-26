class Package < ApplicationRecord
  belongs_to :user

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
  # def merge_tracking_events!(new_events)
  #   self.tracking_events ||= []

  #   # Merge old and new events without duplicates
  #   merged = (new_events + self.tracking_events).uniq { |e| [ e["time_utc"], e["description"] ] }

  #   # Sort descending by UTC time so latest event is first
  #   merged.sort_by! { |e| e["time_utc"] || e["time_iso"] }
  #   merged.reverse!

  #   # Update tracking_events
  #   self.tracking_events = merged

  #   # Update status based on latest event
  #   latest_event = merged.first
  #   self.status = latest_event["stage"] || self.status

  #   # Update last_location and last_update
  #   self.last_location = latest_event["location"] || latest_event.dig("address", "city")
  #   self.last_update = latest_event["time_utc"]

  #   save!(validate: false)
  # end
end
