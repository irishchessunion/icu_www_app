class DeploymentInfo
  DEPLOY_INFO_FILE = Rails.root.join("DEPLOY_INFO").freeze
  REVISION_FILE = Rails.root.join("REVISION").freeze

  attr_reader :deployed_at, :booted_at, :branch, :tag, :commit, :message

  def self.current
    new
  end

  def initialize
    data = file_data.presence || revision_data.presence || git_data

    @deployed_at = parse_time(data["deployed_at"])
    @booted_at   = APP_BOOTED_AT
    @branch      = presence(data["branch"])
    @tag         = presence(data["tag"])
    @commit      = presence(data["commit"])
    @message     = presence(data["message"])
  end

  def uptime_in_words
    return "unknown" unless booted_at

    seconds = (Time.current - booted_at).to_i
    parts = []

    days = seconds / 86_400
    seconds %= 86_400
    hours = seconds / 3_600
    seconds %= 3_600
    minutes = seconds / 60
    seconds %= 60

    parts << "#{days}d" if days.positive?
    parts << "#{hours}h" if hours.positive?
    parts << "#{minutes}m" if minutes.positive?
    parts << "#{seconds}s" if seconds.positive? || parts.empty?

    parts.join(" ")
  end

  private

  def file_data
    return {} unless File.exist?(DEPLOY_INFO_FILE)

    File.readlines(DEPLOY_INFO_FILE, chomp: true).each_with_object({}) do |line, memo|
      key, value = line.split("=", 2)
      next if key.blank? || value.blank?

      memo[key.strip] = value.strip
    end
  rescue StandardError
    {}
  end

  def revision_data
    return {} unless File.exist?(REVISION_FILE)

    { "commit" => presence(File.read(REVISION_FILE).strip) }
  rescue StandardError
    {}
  end

  def git_data
    {
      "branch"  => git("rev-parse", "--abbrev-ref", "HEAD"),
      "tag"     => git("describe", "--tags", "--exact-match"),
      "commit"  => git("rev-parse", "HEAD"),
      "message" => git("log", "-1", "--pretty=%s")
    }
  end

  def git(*args)
    output = IO.popen(["git", *args], err: File::NULL, &:read).to_s.strip
    presence(output)
  rescue StandardError
    nil
  end

  def parse_time(value)
    return nil if value.blank?

    Time.zone.parse(value)
  rescue StandardError
    nil
  end

  def presence(value)
    value.presence
  end
end