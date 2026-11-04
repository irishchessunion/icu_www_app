# Bans vulnerability scanners and throttles IPs that send too many requests.
# Counts are kept in Rails.cache, which production keeps in tmp/cache so all Passenger processes share them.
class Rack::Attack
  # Things no genuine visitor sends: other platforms' files in the path, and SQL injection in the parameters.
  PROBE_PATH  = /\.(php|aspx?|jsp|cgi)\b|\/wp-(admin|login|content|includes)\b|\/\.(env|git)\b/i
  PROBE_PARAM = /waitfor\s+delay|\bsleep\s*\(|\bbenchmark\s*\(|\bunion(\s|\/\*.*?\*\/)+(all\s+)?select\b|information_schema/i

  def self.probe?(req)
    return true if PROBE_PATH.match?(req.path)
    PROBE_PARAM.match?(CGI.unescape(req.query_string)) || PROBE_PARAM.match?(req.POST.to_s)
  rescue StandardError # a malformed body is for Rails to reject, not us
    false
  end

  # Refuse every probe, and ban the IP for an hour after 3 in 10 minutes.
  blocklist("probes") do |req|
    Fail2Ban.filter("probes:#{req.ip}", maxretry: 3, findtime: 10.minutes, bantime: 1.hour) { probe?(req) }
  end

  # Generous for now: check the log for throttled IPs before tightening it.
  throttle("requests per ip", limit: 300, period: 5.minutes) { |req| req.ip }
end

ActiveSupport::Notifications.subscribe(/\A(blocklist|throttle)\.rack_attack\z/) do |name, _start, _finish, _id, payload|
  req = payload[:request]
  Rails.logger.warn("Rack::Attack #{name.split('.').first}: #{req.ip} #{req.request_method} #{req.fullpath}")
end
