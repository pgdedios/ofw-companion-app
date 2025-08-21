module ApplicationHelper
  def titleize_status(status)
    status.to_s.gsub(/([a-z])([A-Z])/, '\1 \2').titleize
  end
end
