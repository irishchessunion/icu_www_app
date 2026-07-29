class Spotlight
  EVENT_ID = 2155

  TITLE_LINES = ["Irish Chess", "Championship", "2026"].freeze
  EYEBROW_HIGHLIGHT = "105th Edition"

  attr_reader :event

  delegate :start_date, :end_date, to: :event

  def self.current
    event = Event.active.find_by(id: EVENT_ID)
    new(event) if event && Date.current <= event.end_date
  end

  def initialize(event)
    @event = event
  end

  def title
    TITLE_LINES.join(" ")
  end

  def title_lines
    TITLE_LINES
  end

  def eyebrow_dates
    if start_date.year == end_date.year && start_date.month == end_date.month
      "#{start_date.mday}–#{end_date.mday} #{start_date.strftime('%B')}"
    else
      event.dates
    end
  end

  def starts_at
    @starts_at ||= start_date.in_time_zone.change(hour: 12)
  end

  def started?
    Time.current >= starts_at
  end

  def lichess_url
    event.live_games_url2.presence
  end

  def stream_url
    event.streaming_url.presence
  end

  def pairings_url
    event.pairings_url.presence
  end

  def results_url
    event.results_url.presence
  end

  def stream_label
    return unless stream_uri
    return "Twitch.tv" if stream_uri.host.to_s.match?(/twitch\.tv/)
    return "YouTube"   if stream_uri.host.to_s.match?(/youtube\.com|youtu\.be/)
  end

  def youtube_video_id
    return unless stream_uri
    case stream_uri.host
    when /youtube\.com/ then CGI.parse(stream_uri.query.to_s)["v"]&.first
    when /youtu\.be/    then stream_uri.path.split("/")[1]
    end
  end

  def twitch_channel_id
    return unless stream_uri
    stream_uri.path.split("/")[1] if stream_uri.host.to_s.match?(/twitch\.tv/)
  end

  def stream_embed?
    youtube_video_id.present? || twitch_channel_id.present?
  end

  private

  def stream_uri
    stream_url ? (URI.parse(stream_url) rescue nil) : nil
  end
end
