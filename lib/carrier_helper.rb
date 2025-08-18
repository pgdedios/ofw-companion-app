module CarrierHelper
  CARRIERS = JSON.parse(File.read(Rails.root.join("lib/carriers.json")))

  def self.code_for(name)
    return nil if name.nil? || name.strip.empty?

    normalized_name = name.strip.downcase

    carrier = CARRIERS.find do |c|
      c["_name"].to_s.strip.downcase == normalized_name
    end

    carrier&.dig("key")
  end
end
