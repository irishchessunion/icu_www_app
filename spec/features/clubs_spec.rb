require 'rails_helper'

describe Club do
  include_context "features"

  let(:country)  { I18n.t("club.county") }
  let(:province) { I18n.t("club.province") }

  context "search" do
    before(:each) do
      create(:club, name: "Bangor", city: "Groomsport", contact: "Mark", county: "down")
      create(:club, name: "Bray/Greystones", city: "Dublin", contact: "Mervyn", county: "dublin")
      create(:club, name: "Aer Lingus", city: "Dublin", contact: "Gearóidín", county: "dublin")
      create(:club, name: "Cortex", city: "Arklow", contact: "Danny", county: "wicklow", active: false)
      visit clubs_path
      @row = "//div[starts-with(@id,'club_')]"
      @search = "Search"
    end

    it "shows all active records by default" do
      expect(page).to have_xpath(@row, count: 3)
    end

    it "find records by name" do
      fill_in name, with: "Lingus"
      click_button @search
      expect(page).to have_xpath(@row, count: 1)
      expect(page).to have_xpath(@row, text: "Aer Lingus")
      fill_in name, with: "b"
      click_button @search
      expect(page).to have_xpath(@row, count: 2)
      expect(page).to have_xpath(@row, text: "Bangor")
      expect(page).to have_xpath(@row, text: "Bray/Greystones")
      fill_in name, with: "/"
      click_button @search
      expect(page).to have_xpath(@row, count: 1)
      expect(page).to have_xpath(@row, text: "Bray/Greystones")
    end

    it "find records by city" do
      fill_in city, with: "Dub"
      click_button @search
      expect(page).to have_xpath(@row, count: 2)
      expect(page).to have_xpath(@row, text: "Bray/Greystones")
      expect(page).to have_xpath(@row, text: "Aer Lingus")
    end

    it "find records by county" do
      select "Dublin", from: country
      click_button @search
      expect(page).to have_xpath(@row, count: 2)
      expect(page).to have_xpath(@row, text: "Bray/Greystones")
      expect(page).to have_xpath(@row, text: "Aer Lingus")
      select "Down", from: country
      click_button @search
      expect(page).to have_xpath(@row, count: 1)
      expect(page).to have_xpath(@row, text: "Bangor")
    end

    it "find records by province" do
      select "Lein", from: province
      click_button @search
      expect(page).to have_xpath(@row, count: 2)
      expect(page).to have_xpath(@row, text: "Bray/Greystones")
      expect(page).to have_xpath(@row, text: "Aer Lingus")
      select "Ulster", from: province
      click_button @search
      expect(page).to have_xpath(@row, count: 1)
      expect(page).to have_xpath(@row, text: "Bangor")
    end

    it "find records by whether active or not" do
      select either, from: active
      click_button @search
      expect(page).to have_xpath(@row, count: 4)
      select active, from: active
      click_button @search
      expect(page).to have_xpath(@row, count: 3)
      select inactive, from: active
      click_button @search
      expect(page).to have_xpath(@row, count: 1)
      expect(page).to have_xpath(@row, text: "Cortex")
    end

    it "return no results when appropriate" do
      select "Ulster", from: province
      fill_in name, with: "Aer"
      click_button @search
      expect(page).to_not have_xpath(@row)
      expect(page).to have_css("div.alert-warning", text: "No matches")
    end

    it "returns to all clubs from a club page" do
      fill_in name, with: "Aer"
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

    it "links to the club's current members, including life members, for logged in users but not guests" do
      season = Season.new.to_s
      paid = create(:player, club: bangor, last_name: "Paid")
      life = create(:player, club: bangor, last_name: "Life")
      lapsed = create(:player, club: bangor, last_name: "Lapsed")
      create(:legacy_subscription_item, player: paid, description: "Standard ICU Subscription #{season}")
      create(:lifetime_subscription, player: life)
      create(:legacy_subscription_item, player: lapsed, description: "Standard ICU Subscription 2012-13")

      visit club_path(bangor)
      expect(page).to_not have_css("#members")

      login "member"
      visit club_path(bangor)
      click_link "2 current members"
      expect(page).to have_css("table tbody tr", count: 2)
      expect(page).to have_css("tbody tr", text: paid.name(reversed: true))
      expect(page).to have_css("tbody tr", text: life.name(reversed: true))
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
