class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    @remittance_centers = current_user.remittance_centers.order(created_at: :desc).limit(3)
  end
end
