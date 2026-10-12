# Base class for the JSON API used by third parties. Every request needs an active API key (see ApiKey),
# sent as "Authorization: Bearer <key>", and each controller says which permission the key must have.
class Api::BaseController < ActionController::API
  before_action :authenticate

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
end
