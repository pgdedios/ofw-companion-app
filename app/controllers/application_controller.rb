class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  # To allow additional parameters in devise.
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :first_name, :last_name, :contact_number, :current_address ])
    devise_parameter_sanitizer.permit(:account_update, keys: [ :first_name, :last_name, :contact_number, :current_address ])
  end

  # To redirect user to login page after logout
  def after_sign_out_path_for(resource_or_scope)
    unauthenticated_root_path
    # new_user_session_path
  end

  # To redirect user to login page after sign up
  def after_inactive_sign_up_path_for(resource)
    new_user_session_path
  end
end
