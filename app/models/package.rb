class Package < ApplicationRecord
  belongs_to :user

  validates :tracking_number, presence: true, uniqueness: { scope: :courier_name }
  validates :courier_name, presence: true
  validates :status, presence: true, on: :update

  # to merge new events in old events json
  def merge_tracking_events!(new_events)
    # initialize if nil
    self.tracking_events ||= []

    merged = (self.tracking_events + new_events).uniq do |e|
      [ e["stage"], e["time_utc"] ]
    end

    self.tracking_events = merged
    save!
  end
end
