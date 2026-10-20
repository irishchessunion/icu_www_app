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

    it "defaults the county from its shareable URL" do
      visit county_clubs_path(county: "dublin")
      expect(page).to have_select(county, selected: "Dublin")
      expect(page).to have_xpath(@row, count: 2)
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

    it "enables only admins and editors to search for inactive clubs" do
      user = login
      visit clubs_path(include_inactive: "on")
      expect(page).not_to have_field("Include inactive")
      expect(page).to have_xpath(@row, count: 3)

      Club.find_by!(name: "Bangor").update!(secretary_id: user.player_id)
      visit clubs_path(include_inactive: "on")
      expect(page).not_to have_field("Include inactive")
      expect(page).to have_xpath(@row, count: 3)
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

  context "live directory", js: true do
    before do
      create(:club, name: "Dublin club", county: "dublin", city: "Dublin", lat: 53.35, long: -6.26)
      create(:club, name: "Wicklow club", county: "wicklow", city: "Bray", lat: 53.2, long: -6.1)
      create(:club, name: "Cork club", county: "cork", city: "Cork", lat: 51.9, long: -8.47)
    end

    it "refreshes without reloading, updates the county URL, and clears every filter" do
      Club.find_by!(name: "Wicklow club").club_meetings.create!(day_of_week: "monday", start_time: "19:00")
      visit clubs_path
      page.execute_script("window.directoryPage = true")
      select "Dublin", from: county
      expect(page).to have_css(".clubs-scroll .list-group-item", count: 1)
      expect(page).to have_current_path(county_clubs_path(county: "dublin"))
      expect(page.evaluate_script("window.directoryPage")).to eq(true)
      expect(page.evaluate_script("document.querySelectorAll('.maplibregl-marker').length")).to eq(3)
      expect(page).to have_css(".maplibregl-marker img[style*='opacity: 0.6']", count: 2, visible: :all)

      fill_in directory_search, with: "Missing club"
      expect(page).to have_content("0 clubs found")
      click_link "Clear search filters"
      expect(page).to have_css(".clubs-scroll .list-group-item", count: 3)
      expect(page).to have_current_path(clubs_path)
      expect(page).to have_field(directory_search, with: "")
      expect(page.evaluate_script("window.directoryPage")).to eq(true)

      choose "Adults-only", allow_label_click: true
      expect(page).to have_css(".clubs-scroll .list-group-item", count: 2)
      expect(page).not_to have_css(".clubs-scroll .list-group-item", text: "Wicklow club")
      expect(page).to have_current_path(clubs_path(audience: "adults_only"))
      click_link "Clear search filters"
      expect(page).to have_css(".clubs-scroll .list-group-item", count: 3)
      expect(page).to have_checked_field("All", visible: :all)
    end

    it "filters across county borders around a location and switches to the map on mobile" do
      create(:club, name: "Wexford club", county: "wexford", city: "Wexford", lat: 52.34, long: -6.46)
      page.current_window.resize_to(390, 844)
      visit clubs_path
      expect(page).to have_select("Search radius", selected: "10km")
      select "25km", from: "Search radius"
      page.execute_script <<~JS
        const position = { coords: { latitude: 53.35, longitude: -6.26 } };
        navigator.geolocation.getCurrentPosition = success => success(position);
        // Exercise the fallback even on browsers that implement the native element.
        const geo = document.querySelector('geolocation');
        const button = geo.querySelector('button');
        geo.replaceWith(button);
      JS
      click_button "Find clubs near me"
      expect(page).to have_css(".clubs-show-map #clubs-map", visible: true)
      expect(page).not_to have_css(".clubs-controls")
      click_link "List"
      expect(page).to have_content("2 clubs found")
      expect(page).to have_select("day_of_week", selected: "Any day")
      controls = find(".clubs-controls").rect
      tabs = find(".list-map-tabs").rect
      expect(controls.y).to be >= tabs.y + tabs.height - 1
      choose "Women-only", allow_label_click: true
      expect(page).to have_content("0 clubs found")
      click_link "Map", exact: true
      expect(page).to have_css(".clubs-show-map #clubs-map", visible: true)
      expect(page).not_to have_css(".clubs-controls")
      click_link "List"
      choose "All", allow_label_click: true
      expect(page).to have_content("2 clubs found")
      expect(page).to have_css(".clubs-scroll .list-group-item", count: 2)
      expect(page).not_to have_css(".clubs-scroll .list-group-item", text: "Cork club")
      select "150km", from: "Search radius"
      expect(page).to have_css(".clubs-scroll .list-group-item", count: 3)
      click_link "Clear search filters"
      expect(page).to have_css(".clubs-scroll .list-group-item", count: 4)
      expect(page).to have_select("Search radius", selected: "10km")
    ensure
      page.current_window.resize_to(1920, 1080)
    end

    it "expands the location radius until a matching club is found, up to 150km" do
      visit clubs_path(search: "Dublin club")
      page.execute_script <<~JS
        navigator.geolocation.getCurrentPosition = success => success({ coords: window.directoryPosition });
        const geo = document.querySelector('geolocation');
        geo.replaceWith(geo.querySelector('button'));
      JS

      [
        [53.35, -6.26, 10, 1],
        [53.2, -6.1, 25, 1],
        [53.7, -6.26, 50, 1],
        [54.0, -6.26, 100, 1],
        [54.4, -6.26, 150, 1],
        [55.5, -6.26, 150, 0]
      ].each do |lat, lng, radius, count|
        select "10km", from: "Search radius"
        page.execute_script("window.directoryPosition = { latitude: #{lat}, longitude: #{lng} }")
        click_button "Find clubs near me"
        expect(page).to have_select("Search radius", selected: "#{radius}km")
        expect(page).to have_content("#{count} clubs found")
      end

      select "10km", from: "Search radius"
      expect(page).to have_select("Search radius", selected: "10km")
      expect(page).to have_css(".panel-pastel-warning", text: "No matches")
    end

    it "scrolls only the results when scrolling over the desktop map" do
      20.times { |i| create(:club, name: "Club #{i}") }
      visit clubs_path
      expect(page).to have_css(".clubs-scroll .list-group-item", count: 23)
      map_top = find(".clubs-map").rect.y
      page.execute_script("document.querySelector('.clubs-map').dispatchEvent(new WheelEvent('wheel', { deltaY: 500, bubbles: true, cancelable: true }))")
      expect(page.evaluate_script("document.querySelector('.clubs-scroll').scrollTop")).to be > 0
      expect(page.evaluate_script("window.scrollY")).to eq(0)
      expect(find(".clubs-map").rect.y).to eq(map_top)
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
