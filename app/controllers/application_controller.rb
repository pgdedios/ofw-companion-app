class ApplicationController < ActionController::Base
  helper_method :use_user_time_zone
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :configure_permitted_parameters, if: :devise_controller?
  around_action :use_user_time_zone, if: :current_user

  protected

  # To allow additional parameters in devise.
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :first_name, :last_name, :contact_number, :current_address, :time_zone ])
    devise_parameter_sanitizer.permit(:account_update, keys: [ :first_name, :last_name, :contact_number, :current_address, :time_zone ])
  end

  # To redirect user to login page after sign up
  def after_inactive_sign_up_path_for(resource)
    new_user_session_path
  end

  def use_user_time_zone(&block)
    Time.use_zone(current_user&.time_zone || "Asia/Manila", &block)
  end
end
