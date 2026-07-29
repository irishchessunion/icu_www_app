require "rails_helper"

describe Spotlight do
  let(:event) { create(:event) }
  let(:spotlight) { described_class.new(event) }

  before { stub_const("Spotlight::EVENT_ID", event.id) }

  describe ".current" do
    it "returns a spotlight for the configured event, nil if it doesn't exist" do
      expect(described_class.current.event).to eq(event)
      stub_const("Spotlight::EVENT_ID", 0)
      expect(described_class.current).to be_nil
    end
  end

  describe "#lichess_url" do
    it "reads live_games_url2, nil when blank" do
      expect(spotlight.lichess_url).to be_nil
      event.update!(live_games_url2: "https://lichess.org/broadcast/x")
      expect(spotlight.lichess_url).to eq("https://lichess.org/broadcast/x")
    end
  end

  describe "stream parsing" do
    it "parses twitch and youtube urls" do
      event.update!(streaming_url: "https://www.twitch.tv/irishchess")
      expect(spotlight.stream_label).to eq("Twitch.tv")
      expect(spotlight.twitch_channel_id).to eq("irishchess")

      event.update!(streaming_url: "https://www.youtube.com/watch?v=abc123")
      expect(spotlight.stream_label).to eq("YouTube")
      expect(spotlight.youtube_video_id).to eq("abc123")
    end
  end
end
