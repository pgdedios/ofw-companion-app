class DashboardController < ApplicationController
  before_action :authenticate_user!

  layout "template"

  def index
    @remittance_centers = current_user.remittance_centers.order(created_at: :desc).limit(3)
    @packages = current_user.packages.order(created_at: :desc)
  end
end
