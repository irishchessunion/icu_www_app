require 'rails_helper'

describe Club do
  include_context "features"

  let(:county) { I18n.t("club.county") }
  let(:directory_search) { I18n.t("club.directory.search") }

  context "search" do
    before(:each) do
      create(:club, name: "Bangor", city: "Groomsport", contact: "Mark", county: "down")
      create(:club, name: "Bray/Greystones", city: "Dublin", contact: "Mervyn", county: "dublin")
      create(:club, name: "Aer Lingus", city: "Dublin", contact: "Gearóidín", county: "dublin")
      create(:club, name: "Cortex", city: "Arklow", contact: "Danny", county: "wicklow", active: false)
      visit clubs_path
      @row = "//a[starts-with(@id,'club_')]"
      @search = "Search"
    end

    it "shows all active records by default" do
      expect(page).to have_xpath(@row, count: 3)
    end

    it "find records by name" do
      fill_in directory_search, with: "Lingus"
      click_button @search
      expect(page).to have_xpath(@row, count: 1)
      expect(page).to have_xpath(@row, text: "Aer Lingus")
      fill_in directory_search, with: "b"
      click_button @search
      expect(page).to have_xpath(@row, count: 3)
      expect(page).to have_xpath(@row, text: "Bangor")
      expect(page).to have_xpath(@row, text: "Bray/Greystones")
      fill_in directory_search, with: "/"
      click_button @search
      expect(page).to have_xpath(@row, count: 1)
      expect(page).to have_xpath(@row, text: "Bray/Greystones")
    end

    it "find records by city" do
      fill_in directory_search, with: "Dub"
      click_button @search
      expect(page).to have_xpath(@row, count: 2)
      expect(page).to have_xpath(@row, text: "Bray/Greystones")
      expect(page).to have_xpath(@row, text: "Aer Lingus")
    end

    it "find records by county" do
      select "Dublin", from: county
      click_button @search
      expect(page).to have_xpath(@row, count: 2)
      expect(page).to have_xpath(@row, text: "Bray/Greystones")
      expect(page).to have_xpath(@row, text: "Aer Lingus")
      select "Down", from: county
      click_button @search
      expect(page).to have_xpath(@row, count: 1)
      expect(page).to have_xpath(@row, text: "Bangor")
    end

    it "allows editors to include inactive clubs" do
      login "editor"
      visit clubs_path
      check "Include inactive"
      click_button @search
      expect(page).to have_xpath(@row, count: 4)
      uncheck "Include inactive"
      click_button @search
      expect(page).to have_xpath(@row, count: 3)
    end

    it "ignores the include inactive parameter for guests" do
      visit clubs_path(include_inactive: "on")
      expect(page).not_to have_field("Include inactive")
      expect(page).to have_xpath(@row, count: 3)
      expect(page).not_to have_content("Cortex")
    end

    it "only enables inactive search for members who can edit a club" do
      user = login
      visit clubs_path(include_inactive: "on")
      expect(page).not_to have_field("Include inactive")
      expect(page).to have_xpath(@row, count: 3)

      Club.find_by!(name: "Bangor").update!(secretary_id: user.player_id)
      visit clubs_path(include_inactive: "on")
      expect(page).to have_checked_field("Include inactive")
      expect(page).to have_xpath(@row, count: 4)
    end

    it "return no results when appropriate" do
      select "Down", from: county
      fill_in directory_search, with: "Aer"
      click_button @search
      expect(page).to_not have_xpath(@row)
      expect(page).to have_css(".clubs-scroll", text: "No matches")
    end

    it "returns to all clubs from a club page" do
      fill_in directory_search, with: "Aer"
      click_button @search
      expect(page).to have_xpath(@row, count: 1)
      click_link "Aer Lingus"
      click_link "All Clubs"
      expect(page).to have_xpath(@row, count: 3)
    end
  end

  context "show" do
    let(:bangor) do
      create(:club,
        name: "Bangor",
        web: "https://chess.bangor.net/about",
        meet: "7pm Tuesdays and Thursdays",
        address: "McKee Clock, Marina",
        district: "Marina",
        city: "Bangor",
        county: "down",
        eircode: "BT20 5ED",
        contact: "Mark Orr",
        email: "mark@bangor.net",
        phone: "07968 537010",
        notes: "Players of all abilities are welcome.",
        active: true
      )
    end

    it "displays the public club details in the event-style layout" do
      visit club_path(bangor)

      expect(page).to have_css(".show-panel h2", text: bangor.name)
      expect(page.all(".show-panel .subtitle div").map(&:text)).to eq ["McKee Clock,", "Marina,", "Bangor,", "Co. Down,", "BT20 5ED"]
      expect(page).to have_link("chess.bangor.net", href: bangor.web)
      expect(page).to have_css("#description", text: bangor.notes)
      expect(page).to have_css("aside.side-content #contact", text: bangor.contact)
      expect(page).to have_link(bangor.contact, href: "mailto:#{bangor.email}")
      expect(page).to have_css("aside.side-content #contact", text: bangor.phone)
      expect(page).to have_link("All Clubs", href: clubs_path)
      expect(page).not_to have_css(".show-panel .details")
      expect(page).to have_css("aside.side-content #meetings", text: bangor.meet)
      expect(page).to have_link(I18n.t("club.meet"), href: "#meetings")
    end

    it "shows all structured meetings in weekday and time order instead of the legacy text" do
      bangor.club_meetings.create!(day_of_week: "friday", start_time: "19:30", title: "Women’s chess", audience: "women_only")
      bangor.club_meetings.create!(day_of_week: "tuesday", start_time: "19:00", title: "Club night", notes: "All levels welcome")
      bangor.club_meetings.create!(day_of_week: "tuesday", start_time: "18:00", title: "Junior coaching", audience: "juniors_only")

      visit club_path(bangor)

      expect(page.all("aside.side-content #meetings .list-group-item strong").map(&:text)).to eq ["Tuesdays at 18:00", "Tuesdays at 19:00", "Fridays at 19:30"]
      expect(page).to have_css("#meetings .label.panel-pastel-info", text: "Juniors only")
      expect(page).to have_css("#meetings .label.panel-pastel-danger", text: "Women only")
      expect(page).to have_css("#meetings .label", count: 2)
      expect(page).to have_css("#meetings", text: "All levels welcome")
      expect(page).not_to have_css("#meetings", text: bangor.meet)
    end

    it "shows an empty state when there are no structured or legacy meetings" do
      club = create(:club, meet: nil)

      visit club_path(club)

      expect(page).to have_css("aside.side-content #meetings", text: I18n.t("club.no_meetings"))
    end

    it "shows the map only when geocoded" do
      ungeocoded = create(:club, lat: nil, long: nil)
      visit club_path(ungeocoded)
      expect(page).not_to have_css("#map-canvas")

      visit club_path(bangor)
      expect(page).to have_css("#map-canvas")
    end
  end
end
