# app/services/package_webhook_service.rb
class PackageWebhookService
  def initialize(tracking_number, payload = nil)
    @tracking_number = tracking_number
    @payload = payload
    @package = Package.find_by(tracking_number: tracking_number)
  end

  def process
    return false unless @package
    return false unless @payload.present?

    # Extract tracking data from webhook payload
    data = @payload["data"] || {}
    track_info = data["track_info"] || {}

    # Use latest status for simple status string
    latest_status = track_info["latest_status"] || {}
    latest_event  = track_info["latest_event"] || {}
    new_status    = latest_status["status"] || latest_event["stage"] || @package.status
    last_location = latest_event["location"]

    # Build tracking events array
    incoming_events = []
    providers = track_info.dig("tracking", "providers") || []

    providers.each do |provider|
      (provider["events"] || []).each do |e|
        incoming_events << {
          "stage"       => e["stage"] || e["sub_status"]&.split("_")&.first,
          "sub_status"  => e["sub_status"],
          "description" => e["description"],
          "location"    => e["location"],
          "time_iso"    => e["time_iso"],
          "time_utc"    => e["time_utc"],
          "address"     => e["address"] || {}
        }
      end
    end

    old_events = @package.tracking_events || []
    old_status = @package.status

    # Merge events and update package status/location
    @package.merge_tracking_events!(incoming_events)
    @package.update(status: new_status, last_location: last_location)

    # Notify user if changes occurred
    if old_events != @package.tracking_events || old_status != @package.status
      notify_user
    end

    true
  end

  private

  def notify_user
    user = @package.user
    return unless user

    # notify user via email
    UserMailer.status_update(user, @package).deliver_now if user.email.present?

    # notify user via sms
    if user.contact_number.present?
      message = "Update on your package #{@package.tracking_number}: #{@package.status.to_s.gsub('_', ' ').capitalize}"

      message = "Update on your package #{@package.tracking_number}: #{@package.status}. Details: #{@package.tracking_events}"
      sms_service = IprogSmsService.new(api_token: ENV["IPROG_API_TOKEN"])
      sms_service.send_sms(number: user.contact_number, message: message)

      # sms_service = SemaphoreSmsService.new(api_key: ENV["SEMAPHORE_API_KEY"])
      # sms_service.send_sms(message: message, number: user.contact_number)
    end
  end
end
