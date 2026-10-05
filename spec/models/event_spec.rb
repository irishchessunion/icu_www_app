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

  context "multi-user access helpers" do
    let(:creator) { create(:user, roles: "organiser") }
    let(:full_user) { create(:user, roles: "organiser") }
    let(:limited_user) { create(:user, roles: "organiser") }
    let(:event) { create(:event, user: creator) }

    before do
      create(:event_user, event: event, user: full_user, role: "full_access")
      create(:event_user, event: event, user: limited_user, role: "limited_access")
    end

    it "creator returns the event's creator user" do
      expect(event.creator).to eq(creator)
    end

    it "creator? returns true for the creator" do
      expect(event.creator?(creator)).to be true
      expect(event.creator?(full_user)).to be false
    end

    it "has_full_access? returns true for creator and full_access users" do
      expect(event.has_full_access?(creator)).to be true
      expect(event.has_full_access?(full_user)).to be true
      expect(event.has_full_access?(limited_user)).to be false
    end

    it "has_limited_access? returns true only for limited_access users" do
      expect(event.has_limited_access?(creator)).to be false
      expect(event.has_limited_access?(full_user)).to be false
      expect(event.has_limited_access?(limited_user)).to be true
    end

    it "has_any_access? returns true for creator, full_access, and limited_access users" do
      other_user = create(:user)
      expect(event.has_any_access?(creator)).to be true
      expect(event.has_any_access?(full_user)).to be true
      expect(event.has_any_access?(limited_user)).to be true
      expect(event.has_any_access?(other_user)).to be false
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

  context "short_event" do
    let(:start) { Date.today.days_since(30) }

    it "is set from the dates, ignoring what was passed in" do
      expect(create(:event, start_date: start, end_date: start, short_event: false).short_event).to be true
      expect(create(:event, start_date: start, end_date: start.days_since(12)).short_event).to be true
      expect(create(:event, start_date: start, end_date: start.days_since(13), short_event: true).short_event).to be false
    end

    it "is recalculated when the end date changes after the event has started" do
      event = create(:event, start_date: start, end_date: start.days_since(2))
      event.update_columns(start_date: Date.today.days_ago(1), end_date: Date.today.days_since(1))
      event.update!(end_date: Date.today.days_since(20))
      expect(event.reload.short_event).to be false
    end

    it "is used for the home page's upcoming events" do
      tournament = create(:event, start_date: start, end_date: start.days_since(2))
      create(:event, name: "League", start_date: start, end_date: start.days_since(60))
      expect(Event.short).to eq [tournament]
    end
  end

  context "details for third party listings" do
    let(:user) { create(:user) }

    it "defaults to an ICU-rated swiss with nothing else known" do
      event = create(:event)
      expect(event.tournament_type).to eq "swiss"
      expect(event.icu_rated).to be true
      expect(event.time_control_details).to be_nil
      expect(event.max_participants).to be_nil
    end

    it "needs a known tournament type" do
      Event::TOURNAMENT_TYPES.each { |type| expect(build(:event, user: user, tournament_type: type)).to be_valid }
      expect(build(:event, user: user, tournament_type: "arena")).to_not be_valid
      expect(build(:event, user: user, tournament_type: nil)).to_not be_valid
    end

    it "stores a blank time control as nil and limits its length" do
      expect(create(:event, time_control_details: " ").time_control_details).to be_nil
      expect(build(:event, user: user, time_control_details: "90+30")).to be_valid
      expect(build(:event, user: user, time_control_details: "x" * 51)).to_not be_valid
    end

    it "needs maximum entries to be a positive whole number, if given" do
      expect(build(:event, user: user, max_participants: 80)).to be_valid
      expect(build(:event, user: user, max_participants: 0)).to_not be_valid
      expect(build(:event, user: user, max_participants: 10.5)).to_not be_valid
    end

    it "can be changed after the event has started but not after it has ended" do
      event = create(:event)
      event.update_columns(start_date: Date.today.days_ago(1), end_date: Date.today.days_since(1))
      expect(event.update(time_control_details: "90+30", tournament_type: "knockout", icu_rated: false, max_participants: 50)).to be true

      event.update_columns(end_date: Date.today.days_ago(1))
      expect(event.update(time_control_details: "60+30")).to be false
    end
  end

  context "fees_by_section" do
    let(:event)   { create(:event, sections: "Masters, Major") }
    let!(:masters) { create(:entry_fee, name: "Masters", event: event, sections: "Masters") }
    let!(:both)    { create(:entry_fee, name: "Both", event: event, sections: "Masters, Major") }

    it "gives each section its active fees" do
      expect(event.fees_by_section).to eq("Masters" => [both, masters], "Major" => [both])
      masters.update_column(:active, false)
      expect(event.reload.fees_by_section).to eq("Masters" => [both], "Major" => [both])
    end

    it "puts every fee in a section called all when the event has none" do
      event = create(:event, name: "Open")
      fee = create(:entry_fee, name: "Open", event: event)
      expect(event.fees_by_section).to eq("all" => [fee])
      expect(create(:event, name: "Free").fees_by_section).to eq("all" => [])
    end
  end

  context "registration_deadline" do
    let(:event) { create(:event) }

    it "is the last day an active fee is on sale" do
      expect(event.registration_deadline).to be_nil
      early = create(:entry_fee, name: "Early", event: event, sale_end: event.start_date.days_ago(10))
      late = create(:entry_fee, name: "Late", event: event, sale_end: event.start_date.days_ago(2))
      expect(event.reload.registration_deadline).to eq late.sale_end
      late.update_column(:active, false)
      expect(event.reload.registration_deadline).to eq early.sale_end
    end
  end

  context "note editing" do
    it "renders legacy Markdown notes without raw HTML" do
      event = create(:event, note: "**Bold** <script>alert(1)</script>")
      expect(event.markdown).to be true
      expect(event.html).to include("<strong>Bold</strong>")
      expect(event.html).to_not include("<script>")
    end

    it "sanitizes notes saved from the editor" do
      event = create(:event, markdown: false, note: "<p><strong>Bold</strong></p><script>alert(1)</script>")
      expect(event.note).to start_with "<p><strong>Bold</strong></p>"
      expect(event.note).to_not include("<script>")
    end

    it "clears an empty editor, since the note is optional" do
      expect(create(:event, markdown: false, note: "<p><br></p>").note).to be_nil
    end

    it "rejects invalid shortcuts" do
      event = build(:event, markdown: false, note: "<p>[IMG:999999]</p>")
      expect(event).to_not be_valid
      expect(event.errors[:note].first).to match(/not a valid image/)
    end

    it "can still update the note after the event has ended, converting it to HTML" do
      event = create(:event, note: "Old **Markdown**")
      event.update_columns(start_date: Date.today.days_ago(10), end_date: Date.today.days_ago(8))
      event.markdown = false
      expect(event.update(note: "<p>Results are in</p>")).to be true
    end
  end
end
