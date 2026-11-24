require 'rails_helper'

describe "Overview players chart", type: :feature, js: true do
  it "switches breakdowns and periods without reloading or refetching cached periods" do
    player = create(:player, joined: Date.current, gender: "F", dob: Date.current.prev_year(20))
    create(:user, player: player)
    create(:player, joined: Date.current.prev_year, gender: "M")
    login "admin"
    visit admin_overview_path

    expect(page).to have_css("#new-players .apexcharts-canvas")
    expect(page).to have_css("#new-players .apexcharts-legend-text", text: "Has User")
    expect(page).to have_css("#new-players .apexcharts-xaxis-texts-g text", count: 12)
    page.execute_script <<~JS
      window.overviewPage = true;
      window.chartRequests = 0;
      const originalFetch = window.fetch;
      window.fetch = (...args) => {
        if (String(args[0]).includes('/overview/new_players')) window.chartRequests++;
        return originalFetch(...args);
      };
    JS

    within "#new-players" do
      choose "Age", allow_label_click: true
      expect(page).to have_css(".apexcharts-legend-text", text: "18-24")
      choose "Gender", allow_label_click: true
      expect(page).to have_css(".apexcharts-legend-text", text: "Female")
      expect(page.evaluate_script("window.chartRequests")).to eq 0

      choose "Season", allow_label_click: true
      expect(page).to have_css(".apexcharts-xaxis-texts-g text", text: Season.new.to_s)
      expect(page).to have_css(".apexcharts-xaxis-texts-g text", count: 8)
      choose "Year", allow_label_click: true
      expect(page).to have_css(".apexcharts-xaxis-texts-g text", text: Date.current.year.to_s)
      expect(page).to have_css(".apexcharts-xaxis-texts-g text", count: 8)
      choose "Month", allow_label_click: true
      expect(page).to have_css(".apexcharts-xaxis-texts-g text", count: 12)
      expect(page).to have_css(".apexcharts-legend-text", text: "Female")
    end

    expect(page.evaluate_script("window.overviewPage")).to eq true
    expect(page.evaluate_script("window.chartRequests")).to eq 2
    expect(page).to have_css("#new-players .apexcharts-canvas", count: 1)
    expect(page).not_to have_content("Unable to load chart")
  end

  it "switches the Active Players period" do
    create(:paid_subscription_item)
    login "admin"
    visit admin_overview_path

    within "#active-players" do
      expect(page).to have_css(".apexcharts-legend-text", text: "New Members")
      expect(page).to have_css(".apexcharts-xaxis-texts-g text", count: 12)
      choose "Season", allow_label_click: true
      expect(page).to have_css(".apexcharts-xaxis-texts-g text", text: Season.new.to_s)
    end

    expect(page).to have_css("#new-players .apexcharts-xaxis-texts-g text", count: 12)
  end

  it "shows empty periods without moving the chart in a dark theme at mobile width" do
    create(:player, joined: Date.current.prev_year(2))
    login create(:user, roles: "treasurer", theme: "Darkly")
    page.current_window.resize_to(390, 844)
    visit admin_overview_path

    expect(page).to have_css("#new-players .apexcharts-canvas")
    expect(page).to have_css("#new-players [role=status]", text: "No data for this period.")
    plot = find("#new-players .chart-plot")
    original_bounds = [plot.native.rect.y, plot.native.rect.height]
    within "#new-players" do
      choose "Age", allow_label_click: true
      expect(page).to have_css(".apexcharts-legend-text", text: "Unknown")
      choose "Year", allow_label_click: true
      expect(page).to have_css(".apexcharts-xaxis-texts-g text", count: 8)
      expect(page).not_to have_content("No data for this period.")
      expect([plot.native.rect.y, plot.native.rect.height]).to eq original_bounds
      choose "Month", allow_label_click: true
      expect(page).to have_css("[role=status]", text: "No data for this period.")
      expect([plot.native.rect.y, plot.native.rect.height]).to eq original_bounds
    end
    expect(page).not_to have_content("Unable to load chart")
    expect(page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth")).to be true
  ensure
    page.current_window.resize_to(1920, 1080)
  end
end
