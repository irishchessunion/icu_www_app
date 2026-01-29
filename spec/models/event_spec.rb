require "rails_helper"

describe Event do
  before do
    allow(Event).to receive(:paginate) { |scope, *_| scope }
  end

  let(:jan) { I18n.t("month.s01") }
  let(:dec) { I18n.t("month.s12") }

  let(:search_path) { "/events" }
  let(:def_search_params) do
    {
      year: Date.today.year.to_s,
      month: "%02d" % Date.today.month
    }
  end

  context "search with include inactive checkbox" do
    let!(:active_event) do
      create(:event, active: true, start_date: Date.today + 10)
    end

    let!(:inactive_event) do
      create(:event, active: false, start_date: Date.today + 10)
    end

    it "excludes inactive events by default" do
      results = Event.search(def_search_params, search_path)

      expect(results).to include(active_event)
      expect(results).not_to include(inactive_event)
    end

    it "includes inactive events when checkbox is toggled on" do
      params = def_search_params.merge(include_inactive: "on")
      results = Event.search(params, search_path)

      expect(results).to include(active_event)
      expect(results).to include(inactive_event)
    end
  end

  context "search with search term" do
    let!(:result_event) do
      create(:event, name: "Dublin Rapid", start_date: Date.today + 10)
    end

    let!(:non_result_event) do
      create(:event, name: "Cork Open", start_date: Date.today + 10)
    end

    it "matches name or location" do
      params = def_search_params.merge(search: "Dublin")
      results = Event.search(params, search_path)

      expect(results).to include(result_event)
      expect(results).not_to include(non_result_event)
    end
  end

  context "search with time controls" do
    let!(:classical_event) do
      create(:event, time_controls: ["classical"], start_date: Date.today + 10)
    end

    let!(:rapid_event) do
      create(:event, time_controls: ["rapid"], start_date: Date.today + 10)
    end

    it "filters results by time control" do
      params = def_search_params.merge(time_controls: "rapid")
      results = Event.search(params, search_path)

      expect(results).to include(rapid_event)
      expect(results).not_to include(classical_event)
    end
  end

  context "search with category" do
    let!(:junior_event) do
      create(:event, category: "junior", start_date: Date.today + 10)
    end

    let!(:foreign_event) do
      create(:event, category: "foreign", start_date: Date.today + 10)
    end

    let!(:irish_event) do
      create(:event, category: "irish", start_date: Date.today + 10)
    end

    it "returns junior and junint for juniors category" do
      params = def_search_params.merge(category: "juniors")
      results = Event.search(params, search_path)

      expect(results).to include(junior_event)
      expect(results).not_to include(foreign_event)
      expect(results).not_to include(irish_event)
    end
  end

  context "multiyear_dates_as_spans" do
    it "returns an array with start date, separator and end date (including year)" do
      start_date = Date.new(2025, 12, 30)
      end_date   = Date.new(2026, 1, 2)

      event = Event.new(start_date: start_date, end_date: end_date)

      expect(event.multiyear_dates_as_spans).to eq(
        ["30 #{dec} 2025", "–", "2 #{jan} 2026"]
      )
    end
  end

  context "admin_search" do
    let(:admin_search_path) { "/admin/events" }
    let(:admin) { create(:user, roles: "admin") }
    let(:organiser1) { create(:user, roles: "organiser") }
    let(:organiser2) { create(:user, roles: "organiser") }

    let(:upcoming_event1) do
      upcoming_event1 = build(:event, name: "Howth Congress", user: organiser1, start_date: Date.today + 10, end_date: Date.today + 12)
      upcoming_event1.save!(validate: false)
      upcoming_event1
    end

    let(:upcoming_event2) do
      upcoming_event2 = build(:event, name: "Drogheda Congress", user: organiser2, start_date: Date.today + 15, end_date: Date.today + 17)
      upcoming_event2.save!(validate: false)
      upcoming_event2
    end

    let(:past_event1) do
      past_event1 = build(:event, name: "Belfast Congress", user: organiser1, start_date: Date.today - 12, end_date: Date.today - 10)
      past_event1.save!(validate: false)
      past_event1
    end

    let(:past_event2) do
      past_event2 = build(:event, name: "Cobh Congress", user: organiser2, start_date: Date.today - 17, end_date: Date.today - 15)
      past_event2.save!(validate: false)
      past_event2
    end

    it "returns upcoming and past events separately" do
      results = Event.admin_search({}, admin_search_path, admin)

      expect(results[:upcoming]).to include(upcoming_event1, upcoming_event2)
      expect(results[:upcoming]).not_to include(past_event1, past_event2)
      expect(results[:past]).to include(past_event1, past_event2)
      expect(results[:past]).not_to include(upcoming_event1, upcoming_event2)
    end

    it "organisers only see their own events" do
      results = Event.admin_search({}, admin_search_path, organiser1)

      expect(results[:upcoming]).to include(upcoming_event1)
      expect(results[:upcoming]).not_to include(upcoming_event2)
      expect(results[:past]).to include(past_event1)
      expect(results[:past]).not_to include(past_event2)
    end

    it "filters by name" do
      results = Event.admin_search({ name: "Dublin" }, admin_search_path, admin)

      expect(results[:upcoming]).not_to include(upcoming_event1)
      expect(results[:upcoming]).not_to include(upcoming_event2)
    end

    it "admins can filter by user_id" do
      results = Event.admin_search({ user_id: organiser1.id }, admin_search_path, admin)

      expect(results[:upcoming]).to include(upcoming_event1)
      expect(results[:upcoming]).not_to include(upcoming_event2)
    end
  end

  context "map_marker_key" do
    it "returns 'other' when time_controls is nil" do
      event = Event.new(time_controls: nil)
      expect(event.map_marker_key).to eq("other")
    end

    it "returns 'other' when time_controls is empty" do
      event = Event.new(time_controls: [])
      expect(event.map_marker_key).to eq("other")
    end

    it "returns the a string when there is one value" do
      event = Event.new(time_controls: ["classical"])
      expect(event.map_marker_key).to eq("classical")
    end

    it "concatenates multiple time controls into a string with underscores" do
      event = Event.new(time_controls: ["classical", "blitz"])
      expect(event.map_marker_key).to eq("classical_blitz")
    end
  end

end
