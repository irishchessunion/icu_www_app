# Base class for the JSON API used by third parties. Every request needs an active API key (see ApiKey),
# sent as "Authorization: Bearer <key>", and each controller says which permission the key must have.
class Api::BaseController < ActionController::API
  class BadRequest < StandardError; end

  before_action :authenticate

  rescue_from BadRequest do |exception|
    render json: { error: exception.message }, status: :bad_request
  end

  private

  # @param permission [String] one of ApiKey::PERMISSIONS
  def self.requires_permission(permission)
    before_action { require_permission(permission) }
  end

  def authenticate
    @api_key = ApiKey.authenticate(request.authorization.to_s[/\ABearer\s+(\S+)\z/, 1])
    return if @api_key
    response.headers["WWW-Authenticate"] = "Bearer"
    render json: { error: "Missing or invalid API key" }, status: :unauthorized
  end

  def require_permission(permission)
    return if @api_key.permits?(permission)
    render json: { error: "This API key doesn't have permission to do that" }, status: :forbidden
  end

  # The methods below read a request parameter, returning nil if it's absent or blank. A value that
  # can't be used is the client's mistake, so they answer with a 400 rather than ignore it.

  def bad_request(message)
    raise BadRequest, message
  end

  def string_param(name)
    value = params[name]
    return nil if value.blank?
    bad_request("#{name} must be a single value") unless value.is_a?(String)
    value.strip
  end

  # @return [Date, nil]
  def date_param(name)
    value = string_param(name) or return nil
    bad_request("#{name} must be a date like 2026-12-31") unless value.match?(/\A\d{4}-\d{2}-\d{2}\z/)
    Date.strptime(value, "%Y-%m-%d")
  rescue Date::Error
    bad_request("#{name} isn't a real date")
  end

  # @return [ActiveSupport::TimeWithZone, nil]
  def time_param(name)
    value = string_param(name) or return nil
    return date_param(name).in_time_zone if value.match?(/\A\d{4}-\d{2}-\d{2}\z/)
    Time.iso8601(value).in_time_zone
  rescue ArgumentError
    bad_request("#{name} must be a date like 2026-12-31 or a time like 2026-12-31T18:30:00Z")
  end

  # @return [Integer, nil]
  def integer_param(name, min: nil, max: nil)
    value = string_param(name) or return nil
    bad_request("#{name} must be a whole number") unless value.match?(/\A\d{1,9}\z/)
    number = value.to_i
    bad_request("#{name} must be at least #{min}") if min && number < min
    bad_request("#{name} must be at most #{max}") if max && number > max
    number
  end

  # @param allowed [Array<String>] the values the list may contain
  # @return [Array<String>, nil] the comma separated values of the parameter
  def list_param(name, allowed)
    value = string_param(name) or return nil
    values = value.split(",").map(&:strip).reject(&:empty?).uniq
    unknown = values - allowed
    bad_request("#{name} must be one or more of #{allowed.join(', ')}") if values.empty? || unknown.any?
    values
  end
end
