class RemittanceCenter < ApplicationRecord
  belongs_to :user
  validates :place_id, uniqueness: { scope: :user_id }
  validates :name, presence: true

  # Builds attributes hash from Google Places API response
  def self.from_google_place(details, place_id)
    {
      place_id: place_id,
      name: details.dig(:name) || "Unnamed Place",
      address: details.dig(:formatted_address) || "No address available",
      latitude: details.dig(:geometry, :location, :lat),
      longitude: details.dig(:geometry, :location, :lng),
      phone: details.dig(:international_phone_number) || "Not available",
      rating: details.dig(:rating) || 0.0,
      user_ratings_total: details.dig(:user_ratings_total) || 0,
      opening_hours: details.dig(:opening_hours, :weekday_text) || []
    }
  end

  # Updates the center with fresh Google Place details
  def update_with_place_details(details)
    assign_attributes(self.class.from_google_place(details, self.place_id))
    save
  end
end
