class PackageWebhookService
  def initialize(tracking_number, payload = nil)
    @tracking_number = tracking_number
    @payload = payload
    @package = Package.find_by(tracking_number: tracking_number)
  end

  def process
    return false unless @package && @payload.present?

    # Normalize API vs Webhook format into a consistent array of hashes
    normalized_payload =
      if @payload.is_a?(Hash) && @payload["data"].is_a?(Array)
        @payload["data"]
      elsif @payload.is_a?(Hash) && @payload["data"].present?
        [ @payload["data"] ]
      elsif @payload.is_a?(Array)
        @payload
      else
        []
      end

    # Always take the first element (since we store as array of hashes)
    # Pick the payload that has at least one event with a "stage"
    first_payload = normalized_payload.find do |p|
      events = p.dig("track_info", "tracking", "providers", 0, "events") || []
      events.any? { |e| e["stage"].present? }
    end || {}

    events_history = first_payload.dig("track_info", "tracking", "providers", 0, "events") || []
    latest_event   = events_history.first || {}

    # Determine values with fallbacks
    last_update = latest_event["time_utc"]
    stage = latest_event["stage"] ||
            latest_event["sub_status"].to_s.split("_").first
                          .gsub(/([a-z])([A-Z])/, '\1 \2')
                          .titleize
    location = latest_event["location"] || begin
      addr = latest_event["address"]
      [ addr["city"], addr["state"] ].compact.join(", ") if addr
    end
    description = latest_event["description"]

    # Update only if something changed
    if @package.full_payload != normalized_payload
      @package.update(
        tracking_events: events_history,
        status: stage || @package.status,
        last_update: last_update,
        last_location: location,
        latest_description: description,
        latest_stage: stage,
        latest_substatus: latest_event["sub_status"],
        latest_event_raw: latest_event,
        tracking_provider: first_payload.dig("track_info", "tracking", "providers", 0, "provider", "name"),
        full_payload: normalized_payload
      )

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
      formatted_status = @package.status.to_s
                          .gsub(/([a-z])([A-Z])/, '\1 \2')
                          .titleize
      message = "Update on your package #{@package.tracking_number}:\n#{formatted_status}#{@package.last_location.present? ? " at #{@package.last_location}" : ""}.\nThank you for using OFW Companion"
      sms_service = IprogSmsService.new(api_token: ENV["IPROG_API_TOKEN"])
      sms_service.send_sms(number: user.contact_number, message: message)
    end
  end
end
