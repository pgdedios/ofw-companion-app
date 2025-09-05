class PlacesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_search_params, only: [ :index ]
  before_action :set_google_service, only: [ :index ]

  layout "template"

  def index
    @places = fetch_places
  end

  private

  def set_search_params
    @location = params[:location]
    @radius = [ params[:radius]&.to_i, 5000 ].compact.max
    @keyword = params[:keyword].presence || "remittance center"
  end

  def set_google_service
    @service = GooglePlacesService.new
  end

  def fetch_places
    return [] unless @location.present?

    begin
      raw_places = @service.nearby_search(
        location: @location,
        radius: @radius,
        keyword: @keyword
      )

      raw_places.map do |place|
        {
          place_id: place[:place_id],
          name: place[:name] || "Unnamed Place",
          address: place[:vicinity] || "No address available",
          latitude: place.dig(:geometry, :location, :lat),
          longitude: place.dig(:geometry, :location, :lng),
          rating: place[:rating] || 0.0,
          user_ratings_total: place[:user_ratings_total] || 0,
          saved: current_user.remittance_centers.exists?(place_id: place[:place_id])
        }
      end
    rescue => e
      Rails.logger.error("[PlacesController] Error fetching places: #{e.message}")
      flash.now[:alert] = "Failed to fetch nearby places. Please try again later."
      []
    end
  end
end
