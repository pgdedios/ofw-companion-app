class UserMailer < ApplicationMailer
  default from: "kidmilanoy@gmail.com"

   def status_update(user, package)
    @user = user
    @package = package

    utc_time = Time.iso8601(@package.tracking_events.last["time_utc"])
    Rails.logger.info "DEBUG UTC: #{utc_time}"

    @last_update_time = utc_time.in_time_zone(user.time_zone)
    Rails.logger.info "DEBUG USER TZ (#{user.time_zone}): #{@last_update_time}"

    mail(to: @user.email, subject: "Update on your package #{package.tracking_number}")
  end
end
