# app/services/package_webhook_service.rb
class PackageWebhookService
  def initialize(tracking_number)
    @tracking_number = tracking_number
    @package = Package.find_by(tracking_number: tracking_number)
  end

  def process
    return false unless @package

    service = TrackingService.new(@package.tracking_number, @package.courier_name)
    tracking_data = service.track.first
    return false unless tracking_data

    old_events = @package.tracking_events || []
    old_status = @package.status

    # Merge new events and update status
    @package.merge_tracking_events!(tracking_data[:events])
    @package.update(status: tracking_data[:status])

    # Notify user if changes occurred
    if old_events != @package.tracking_events || old_status != @package.status
      notify_user
    end

    # Optionally, send to Zapier
    send_to_zapier

    true
  end

  private

  def notify_user
    user = @package.user
    return unless user&.email.present?

    # Correct call:
    UserMailer.status_update(user, @package).deliver_now

    if user.contact_number.present?
      TwilioService.send_sms(
        user.contact_number,
        "Package #{@package.tracking_number} updated. Status: #{@package.status}"
      )
    end
  end

  def send_to_zapier
    payload = {
      tracking_number: @package.tracking_number,
      status: @package.status,
      user_email: @package.user.email,
      user_phone: @package.user.contact_number,
      message: "Package #{@package.tracking_number} updated. Status: #{@package.status}"
    }

    zapier_url = ENV["ZAPIER_WEBHOOK_URL"]
    return unless zapier_url.present?

    uri = URI(zapier_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Post.new(uri, "Content-Type" => "application/json")
    request.body = payload.to_json
    http.request(request)
  rescue => e
    Rails.logger.error "Zapier webhook error: #{e.message}"
  end
end
