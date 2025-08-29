class RemittanceCentersController < ApplicationController
  before_action :authenticate_user!

  layout "template"

  def index
    @remittance_centers = current_user.remittance_centers
  end

  def destroy
    center = current_user.remittance_centers.find(params[:id])
    center.destroy
    redirect_to remittance_centers_path, notice: "Remittance center removed."
  end

  def map
    centers = current_user.remittance_centers.where.not(latitude: nil, longitude: nil)

    if centers.any?
      waypoints = centers.map { |c| "#{c.latitude},#{c.longitude}" }.join("/")
      redirect_to "https://www.google.com/maps/dir/#{waypoints}", allow_other_host: true
    else
      redirect_to remittance_centers_path, alert: "No saved remittance centers with coordinates."
    end
  end
end
