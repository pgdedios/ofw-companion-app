class RemittanceCentersController < ApplicationController
  before_action :authenticate_user!

  def index
    @remittance_centers = current_user.remittance_centers
  end

  def destroy
    center = current_user.remittance_centers.find(params[:id])
    center.destroy
    redirect_to remittance_centers_path, notice: "Remittance center removed."
  end
end
