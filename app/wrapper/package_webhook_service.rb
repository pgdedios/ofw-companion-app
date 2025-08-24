class PackageWebhookService
  def initialize(tracking_number, payload = nil)
    @tracking_number = tracking_number
    @payload = payload
    @package = Package.find_by(tracking_number: tracking_number)
  end

  def process
    return false unless @package && @payload.present?

    events = Array(@payload.dig("data", "track_info", "tracking", "providers", 0, "events")) || []
    latest_event = events.last || {}

    # Determine values with fallbacks
    last_update = latest_event["time_utc"] || latest_event["time_iso"]
    stage = latest_event["stage"] || latest_event["sub_status"]
    location = latest_event["location"] || begin
      addr = latest_event.dig("address")
      [ addr["city"], addr["state"] ].compact.join(", ") if addr
    end
    description = latest_event["description"]

    # Update only if something changed
    if @package.tracking_events != events
      # update package columns first
      @package.update(
        tracking_events: events,
        status: stage || @package.status,
        last_update: last_update,
        last_location: location,
        latest_description: description,
        latest_stage: stage,
        latest_substatus: latest_event["sub_status"],
        latest_event_raw: latest_event,
        tracking_provider: @payload.dig("data", "track_info", "tracking", "providers", 0, "provider", "name")
      )

      # notify user after updating columns
      notify_user
    end

    true
  end

  private

  def notify_user
    user = @package.user
    return unless user

    if user.email.present?
      # Pass package and safely read last_update in mailer
      @last_update_time = @package.last_update
      UserMailer.status_update(user, @package).deliver_now
    end

    if user.contact_number.present?
      message = "Update on your package #{@package.tracking_number}: #{@package.status} at #{@package.last_location}.\nThank you for using OFW Companion"
      sms_service = IprogSmsService.new(api_token: ENV["IPROG_API_TOKEN"])
      sms_service.send_sms(number: user.contact_number, message: message)
    end
  end
end
