require 'rails_helper'

describe "Events API", type: :request do
  let(:path)    { "/api/v1/events" }
  let(:api_key) { create(:api_key, permissions: "events") }
  let(:headers) { { "Authorization" => "Bearer #{api_key.key}" } }

  # These are methods, not lets, as some examples make more than one request.
  def json
    JSON.parse(response.body)
  end

  def events
    json["events"]
  end

  def names
    events.map { |e| e["name"] }
  end

  def day(n)
    Date.today.days_since(n)
  end

  # Events can't be created in the past, so create one and then move it.
  def create_past_event(name, start_date, end_date)
    create(:event, name: name).tap { |e| e.update_columns(start_date: start_date, end_date: end_date) }
  end

  def fetch(params = {})
    get path, params: params, headers: headers
  end

  def expect_bad_request(text)
    expect(response).to have_http_status(:bad_request)
    expect(response.media_type).to eq "application/json"
    expect(json.keys).to eq %w[error]
    expect(json["error"]).to include text
  end

  context "path" do
    let!(:event) { create(:event) }

    it "needs the version" do
      get "/api/events", headers: headers
      expect(response.media_type).to_not eq "application/json"
      expect(response.body).to_not include event.name
    end
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
      fetch
    end

    it "responds with JSON" do
      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq "application/json"
      expect(json.keys).to eq %w[page per_page total total_pages events]
      expect(events.size).to eq 1
    end

    it "includes the event's details" do
      expect(events.first).to include(
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
      expect(events.first["latitude"].to_f).to eq 53.259
      expect(events.first["longitude"].to_f).to eq(-9.077)
    end

    it "includes the fixed values" do
      expect(events.first).to include(
        "country_code"        => "IRL",
        "tournament_type"     => "swiss",
        "is_nationally_rated" => true,
      )
    end

    it "is JSON even when another format is asked for" do
      get path, headers: headers.merge("Accept" => "text/html")
      expect(response.media_type).to eq "application/json"
    end
  end

  context "format" do
    it "defaults to classical when the event has no time controls" do
      event = create(:event)
      event.update_column(:time_controls, [])
      fetch
      expect(events.first["format"]).to eq "classical"
      expect(events.first["time_control"]).to eq []
    end
  end

  context "which events" do
    let!(:later)    { create(:event, name: "Later", start_date: day(40), end_date: day(42)) }
    let!(:sooner)   { create(:event, name: "Sooner", start_date: day(20), end_date: day(22)) }
    let!(:inactive) { create(:event, name: "Inactive", start_date: day(30), end_date: day(32), active: false) }

    it "lists active events in date order" do
      fetch
      expect(names).to eq %w[Sooner Later]
    end

    it "is empty when there are none" do
      Event.update_all(active: false)
      fetch
      expect(response).to have_http_status(:ok)
      expect(events).to eq []
      expect(json).to include("total" => 0, "total_pages" => 0, "page" => 1)
    end

    context "from" do
      let!(:past)    { create_past_event("Past", day(-10), day(-8)) }
      let!(:ongoing) { create_past_event("Ongoing", day(-1), day(1)) }
      let!(:today)   { create_past_event("Today", day(-2), day(0)) }

      it "defaults to today, so finished events are left out" do
        fetch
        expect(names).to eq %w[Today Ongoing Sooner Later]
      end

      it "can go back to include finished events" do
        fetch(from: day(-8).to_s)
        expect(names).to eq %w[Past Today Ongoing Sooner Later]
      end

      it "leaves out events that end before it" do
        fetch(from: day(23).to_s)
        expect(names).to eq %w[Later]
      end

      it "includes an event that ends on it" do
        fetch(from: day(22).to_s)
        expect(names).to eq %w[Sooner Later]
      end

      it "uses the default when blank" do
        fetch(from: "")
        expect(names).to eq %w[Today Ongoing Sooner Later]
      end
    end

    context "to" do
      it "leaves out events that start after it" do
        fetch(to: day(39).to_s)
        expect(names).to eq %w[Sooner]
      end

      it "includes an event that starts on it" do
        fetch(to: day(40).to_s)
        expect(names).to eq %w[Sooner Later]
      end

      it "combines with from" do
        create(:event, name: "Latest", start_date: day(60), end_date: day(62))
        fetch(from: day(30).to_s, to: day(50).to_s)
        expect(names).to eq %w[Later]
      end

      it "can be the same day as from" do
        fetch(from: day(21).to_s, to: day(21).to_s)
        expect(names).to eq %w[Sooner]
      end

      it "can't be before from" do
        fetch(from: day(30).to_s, to: day(29).to_s)
        expect_bad_request "to can't be before from"
      end

      it "can't be before today when from is defaulted" do
        fetch(to: day(-1).to_s)
        expect_bad_request "to can't be before from"
      end
    end

    context "bad dates" do
      it "rejects a date in the wrong format" do
        ["next week", "31-12-2026", "2026/12/31", "2026-12-31T10:00:00Z", "20261231"].each do |value|
          fetch(from: value)
          expect_bad_request "from must be a date like"
        end
      end

      it "rejects a date that doesn't exist" do
        fetch(to: "2026-13-45")
        expect_bad_request "to isn't a real date"
      end

      it "rejects a repeated parameter" do
        fetch(from: [day(1).to_s, day(2).to_s])
        expect_bad_request "from must be a single value"
      end

      it "no longer knows the old parameter names" do
        fetch(start_date: day(23).to_s, end_date: day(39).to_s)
        expect(names).to eq %w[Sooner Later]
      end
    end

    context "category" do
      let!(:junior)  { create(:event, name: "Junior", category: "junior", start_date: day(5), end_date: day(5)) }
      let!(:foreign) { create(:event, name: "Foreign", category: "foreign", start_date: day(6), end_date: day(9)) }

      it "is every category by default" do
        fetch
        expect(names).to eq %w[Junior Foreign Sooner Later]
      end

      it "can be one category" do
        fetch(category: "irish")
        expect(names).to eq %w[Sooner Later]
      end

      it "can be several categories" do
        fetch(category: "junior, foreign")
        expect(names).to eq %w[Junior Foreign]
      end

      it "combines with dates" do
        fetch(category: "irish,junior", to: day(25).to_s)
        expect(names).to eq %w[Junior Sooner]
      end

      it "must be a known category" do
        ["scottish", "irish,scottish", ","].each do |value|
          fetch(category: value)
          expect_bad_request "category must be one or more of irish, junior, women, foreign, junint"
        end
      end
    end

    context "updated_since" do
      before(:each) do
        sooner.update_column(:updated_at, Time.zone.parse("2026-03-01 09:00:00"))
        later.update_column(:updated_at, Time.zone.parse("2026-03-10 15:30:00"))
      end

      it "leaves out events last changed before a date" do
        fetch(updated_since: "2026-03-02")
        expect(names).to eq %w[Later]
      end

      it "takes a date as the start of that day" do
        fetch(updated_since: "2026-03-01")
        expect(names).to eq %w[Sooner Later]
      end

      it "takes a time" do
        fetch(updated_since: Time.zone.parse("2026-03-10 15:30:00").iso8601)
        expect(names).to eq %w[Later]

        fetch(updated_since: Time.zone.parse("2026-03-10 15:30:01").utc.iso8601)
        expect(names).to eq []
      end

      it "still leaves out finished events unless from says otherwise" do
        past = create_past_event("Past", day(-10), day(-8))
        fetch(updated_since: "2026-03-02")
        expect(names).to eq %w[Later]

        fetch(updated_since: "2026-03-02", from: day(-10).to_s)
        expect(names).to eq %w[Past Later]
      end

      it "must be a date or time" do
        ["yesterday", "2026-03-10 15:30", "2026-02-30", "1700000000"].each do |value|
          fetch(updated_since: value)
          expect(response).to have_http_status(:bad_request)
          expect(json["error"]).to include "updated_since"
        end
      end
    end
  end

  context "pagination" do
    before(:each) do
      5.times { |i| create(:event, name: "Event #{i + 1}", start_date: day(10 + i), end_date: day(11 + i)) }
    end

    it "returns everything on one page when there's room" do
      fetch
      expect(json).to include("page" => 1, "per_page" => 50, "total" => 5, "total_pages" => 1)
      expect(names).to eq ["Event 1", "Event 2", "Event 3", "Event 4", "Event 5"]
    end

    it "splits the events into pages" do
      fetch(per_page: 2)
      expect(json).to include("page" => 1, "per_page" => 2, "total" => 5, "total_pages" => 3)
      expect(names).to eq ["Event 1", "Event 2"]

      fetch(per_page: 2, page: 2)
      expect(json).to include("page" => 2, "total" => 5)
      expect(names).to eq ["Event 3", "Event 4"]

      fetch(per_page: 2, page: 3)
      expect(names).to eq ["Event 5"]
    end

    it "is empty past the last page" do
      fetch(per_page: 2, page: 4)
      expect(response).to have_http_status(:ok)
      expect(json).to include("page" => 4, "total" => 5, "total_pages" => 3)
      expect(events).to eq []
    end

    it "counts only the events that match the filters" do
      fetch(per_page: 2, to: day(12).to_s)
      expect(json).to include("total" => 3, "total_pages" => 2)
    end

    it "keeps events with the same dates and name in a fixed order" do
      Event.update_all(name: "Same", start_date: day(10), end_date: day(11))
      ids = (1..5).map do |page|
        fetch(per_page: 1, page: page)
        events.first["external_id"]
      end
      expect(ids).to eq Event.order(:id).map { |e| "ICU-EVENT-#{e.id}" }
    end

    it "allows up to 100 per page" do
      fetch(per_page: 100)
      expect(json["per_page"]).to eq 100

      fetch(per_page: 101)
      expect_bad_request "per_page must be at most 100"
    end

    it "rejects a bad page or per_page" do
      { page: %w[0 -1 two 1.5], per_page: %w[0 -5 lots] }.each do |name, values|
        values.each do |value|
          fetch(name => value)
          expect(response).to have_http_status(:bad_request)
          expect(json["error"]).to include name.to_s
        end
      end
    end
  end

  context "API key" do
    let!(:event) { create(:event) }

    def expect_error(status)
      expect(response).to have_http_status(status)
      expect(response.media_type).to eq "application/json"
      expect(json.keys).to eq %w[error]
      expect(response.body).to_not include event.name
    end

    it "is required" do
      get path
      expect_error(:unauthorized)
      expect(response.headers["WWW-Authenticate"]).to eq "Bearer"
    end

    it "must be right" do
      get path, headers: { "Authorization" => "Bearer #{'0' * 64}" }
      expect_error(:unauthorized)
    end

    it "must be active" do
      api_key.update!(active: false)
      fetch
      expect_error(:unauthorized)
    end

    it "must be sent as a bearer token" do
      get path, headers: { "Authorization" => api_key.key }
      expect_error(:unauthorized)

      get path, params: { key: api_key.key, api_key: api_key.key }
      expect_error(:unauthorized)
    end

    it "must have permission to access events" do
      api_key.update!(permissions: nil)
      fetch
      expect_error(:forbidden)
    end

    it "is checked before the parameters" do
      get path, params: { from: "nonsense" }
      expect_error(:unauthorized)
    end

    it "works without a login" do
      fetch
      expect(response).to have_http_status(:ok)
      expect(names).to eq [event.name]
    end
  end
end
