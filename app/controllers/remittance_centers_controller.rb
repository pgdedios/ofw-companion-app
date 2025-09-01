class RemittanceCentersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_google_service, only: [ :create, :refresh ]

  layout "template"

  def index
    @remittance_centers = current_user.remittance_centers
  end

  def create
    place_id = params.dig(:place, :place_id)
    details = @service.fetch_place_details(place_id)

    place_params = RemittanceCenter.from_google_place(details, place_id)

    remittance_center = current_user.remittance_centers.find_or_create_by(place_id: place_id) do |rc|
      rc.assign_attributes(place_params)
    end

    # For Turbo Stream
    respond_to do |format|
      if remittance_center.persisted?
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "place_#{params[:place][:place_id]}",
            partial: "places/saved_button",
            locals: { place_id: params[:place][:place_id] }
          )
        end
        format.html { redirect_back(fallback_location: root_path, notice: "Place saved!") }
      else
        format.html { redirect_back(fallback_location: root_path, alert: "Failed to save place.") }
      end
    end
  end

  def destroy
    center = current_user.remittance_centers.find(params[:id])
    center.destroy
    redirect_to remittance_centers_path, notice: "Remittance center \"#{center.name}\" has been removed."
  end

  def refresh
    updated_count = 0
    failed_count = 0

    current_user.remittance_centers.find_each do |center|
      begin
        details = @service.fetch_place_details(center.place_id)
        if details.present? && center.update_with_place_details(details)
          updated_count += 1
        else
          failed_count += 1
        end
      rescue => e
        Rails.logger.error "Failed to refresh remittance center ID=#{center.id}: #{e.message}"
        failed_count += 1
      end
    end

    flash_message(updated_count, failed_count)
    redirect_to remittance_centers_path
  end

  private

  def set_google_service
    @service = GooglePlacesService.new
  end

  def flash_message(updated_count, failed_count)
    case
    when updated_count.positive? && failed_count.zero?
      flash[:notice] = "All remittance centers have been refreshed successfully."
    when failed_count.positive? && updated_count.zero?
      flash[:alert] = "Failed to refresh any remittance centers."
    when failed_count.positive?
      flash[:notice] = "#{updated_count} center(s) updated, but #{failed_count} could not be refreshed."
    else
      flash[:notice] = "All centers were already up to date."
    end
  end
end
