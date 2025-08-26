
class PlacesController < ApplicationController
  before_action :authenticate_user!

  def index
    @places = []
    @saved_place_ids = current_user.remittance_centers.pluck(:place_id)

    if params[:cached_places].present?
      @places = JSON.parse(params[:cached_places])
    elsif params[:location].present?
      service = GooglePlacesService.new
      response = service.nearby_search(
        location: params[:location],
        radius: params[:radius] || 1000,
        keyword: params[:keyword] || "remittance",
        type: params[:type]
      )
      @places = response["results"] || []
    end
  end


  def save
    current_user.remittance_centers.find_or_create_by(
      place_id: params[:place_id],
      name: params[:name],
      address: params[:address],
      latitude: params[:lat],
      longitude: params[:lng]
    )

    redirect_to places_path(
      location: params[:location],
      radius: params[:radius],
      keyword: params[:keyword],
      lat: params[:lat],
      lng: params[:lng],
      cached_places: params[:cached_places]
    ), notice: "Remittance center saved!"
  end


  def geocode_address
    address = params[:address]
    service = GooglePlacesService.new
    result = service.geocode_address(address)

    if result["status"] == "OK"
      location = result["results"][0]["geometry"]["location"]
      render json: { lat: location["lat"], lng: location["lng"] }
    else
      render json: { error: "Geocoding failed" }, status: :unprocessable_entity
    end
  end
end
