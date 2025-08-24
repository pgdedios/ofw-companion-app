class UserMailer < ApplicationMailer
  default from: "kidmilanoy@gmail.com"

  def status_update(user, package)
    @user = user
    @package = package

    # Use last_update column instead of digging into JSON
    @last_update_time = @package.last_update&.in_time_zone(user.time_zone)
    @last_location = @package.last_location
    @latest_description = @package.latest_description

    mail(to: @user.email, subject: "Update on your package #{package.tracking_number}")
  end
end
