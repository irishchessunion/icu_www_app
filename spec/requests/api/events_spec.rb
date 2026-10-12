require 'rails_helper'

describe "Events API", type: :request do
  let(:json) { JSON.parse(response.body) }
  let(:names) { json.map { |e| e["name"] } }

  def day(n)
    Date.today.days_since(n)
  end

  context "fields" do
    let!(:event) do
      create(:event,
        name: "Galway Congress",
        location: "Salthill Hotel, Galway",
        start_date: day(10),
        end_date: day(12),
        lat: 53.2590000,
        long: -9.0770000,
        time_controls: %w[rapid blitz],
        is_fide_rated: true,
        note: "Six rounds",
        contact: "Mary Murphy",
        url: "http://galwaychess.example.com",
      )
    end

    before(:each) do
      get "/api/events"
    end

    it "responds with JSON" do
      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq "application/json"
      expect(json.size).to eq 1
    end

    it "includes the event's details" do
      expect(json.first).to include(
        "external_id"   => "ICU-EVENT-#{event.id}",
        "name"          => "Galway Congress",
        "start_date"    => day(10).to_s,
        "end_date"      => day(12).to_s,
        "address"       => "Salthill Hotel, Galway",
        "time_control"  => %w[rapid blitz],
        "format"        => "rapid",
        "is_fide_rated" => true,
        "description"   => "Six rounds",
        "contact"       => "Mary Murphy",
        "image"         => "http://galwaychess.example.com",
        "external_registration_url" => "https://icu.ie/events/#{event.id}",
      )
      expect(json.first["latitude"].to_f).to eq 53.259
      expect(json.first["longitude"].to_f).to eq(-9.077)
    end

    it "includes the fixed values" do
      expect(json.first).to include(
        "country_code"        => "IRL",
        "tournament_type"     => "swiss",
        "is_nationally_rated" => true,
      )
    end

    it "is JSON even when another format is asked for" do
      get "/api/events", headers: { "Accept" => "text/html" }
      expect(response.media_type).to eq "application/json"
    end
  end

  context "format" do
    it "defaults to classical when the event has no time controls" do
      event = create(:event)
      event.update_column(:time_controls, [])
      get "/api/events"
      expect(json.first["format"]).to eq "classical"
      expect(json.first["time_control"]).to eq []
    end
  end

  context "which events" do
    let!(:later)    { create(:event, name: "Later", start_date: day(40), end_date: day(42)) }
    let!(:sooner)   { create(:event, name: "Sooner", start_date: day(20), end_date: day(22)) }
    let!(:inactive) { create(:event, name: "Inactive", start_date: day(30), end_date: day(32), active: false) }

    it "lists active events in date order" do
      get "/api/events"
      expect(names).to eq %w[Sooner Later]
    end

    it "is empty when there are none" do
      Event.update_all(active: false)
      get "/api/events"
      expect(response).to have_http_status(:ok)
      expect(json).to eq []
    end

    it "doesn't need a login" do
      get "/api/events"
      expect(response).to have_http_status(:ok)
    end

    context "start_date" do
      it "leaves out events that end before it" do
        get "/api/events", params: { start_date: day(23).to_s }
        expect(names).to eq %w[Later]
      end

      it "includes an event that ends on it" do
        get "/api/events", params: { start_date: day(22).to_s }
        expect(names).to eq %w[Sooner Later]
      end
    end

    context "end_date" do
      it "leaves out events that start after it" do
        get "/api/events", params: { end_date: day(39).to_s }
        expect(names).to eq %w[Sooner]
      end

      it "includes an event that starts on it" do
        get "/api/events", params: { end_date: day(40).to_s }
        expect(names).to eq %w[Sooner Later]
      end
    end

    it "combines start_date and end_date" do
      create(:event, name: "Latest", start_date: day(60), end_date: day(62))
      get "/api/events", params: { start_date: day(30).to_s, end_date: day(50).to_s }
      expect(names).to eq %w[Later]
    end

    it "ignores dates it can't parse" do
      get "/api/events", params: { start_date: "next week", end_date: "2026-13-45" }
      expect(response).to have_http_status(:ok)
      expect(names).to eq %w[Sooner Later]
    end
  end
end
