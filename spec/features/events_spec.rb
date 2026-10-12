require 'rails_helper'

describe Event do
  include_context "features"

  let(:user) { create(:user, roles: "organiser") }
  let(:event) {
    create(:event,
      name: "Irish Open 26",
      user: user,
      note: "5-round weekender, classical, ICU-rated",
      url: "http://irishopen.com/2026/index",
      subscription_required: false
    )
  }

  context "public show page" do
    it "displays event details" do
      visit event_path(event)
      expect(page).to have_css("h2", text: event.name)
      expect(page).to have_content(event.location)
      expect(page).to have_link(href: event.url)
      expect(page).to have_content(I18n.t("event.description"))
      expect(page).to have_content("5-round weekender, classical, ICU-rated")
    end

    it "shows the map only when geocoded" do
      visit event_path(event)
      expect(page).not_to have_css("#map-canvas")

      geocoded = create(:event, lat: 52.6, long: -8.6)
      visit event_path(geocoded)
      expect(page).to have_css("#map-canvas")
    end

    it "shows the enter section only when on-sale fees exist" do
      visit event_path(event)
      expect(page).not_to have_css("#enter")

      create(:entry_fee, event: event)
      visit event_path(event)
      expect(page).to have_css("#enter")
    end

    it "shows the entries section only when paid entries exist" do
      visit event_path(event)
      expect(page).not_to have_css("#entries")

      fee = create(:entry_fee, event: event)
      create(:paid_entry_item, fee: fee)
      visit event_path(event)
      expect(page).to have_css("#entries")
    end
  end

  context "admin/organiser show page" do
    it "shows the admin panel to the event creator" do
      login event.user
      visit event_path(event)
      expect(page).to have_link("Manage Event")
    end

    it "hides the admin panel from guests" do
      visit event_path(event)
      expect(page).not_to have_link("Manage Event")
      expect(page).not_to have_button("View changelog")
    end
  end

  context "entry list CSV downloads" do
    let(:paid_cart) { create(:cart, status: "paid", payment_completed: Time.zone.local(2026, 9, 15, 10)) }
    let!(:entry)    { create(:paid_entry_item, cart: paid_cart, fee: create(:entry_fee, event: event), created_at: Time.zone.local(2026, 6, 1, 12)) }

    before(:each) do
      login "admin"
    end

    it "the event download has no paid date column" do
      visit csv_list_event_path(event)
      rows = CSV.parse(page.body)
      expect(rows[1]).to include "Date"
      expect(rows[1]).to_not include "Paid-Date"
      expect(rows[2].first).to eq "2026-06-01"
      expect(rows[2]).to_not include "2026-09-15"
    end

    it "the admin items download has one" do
      visit admin_items_path(commit: "Generate CSV")
      rows = CSV.parse(page.body)
      expect(rows[1].first(2)).to eq %w(Date Paid-Date)
      expect(rows[2].first(2)).to eq %w(2026-06-01 2026-09-15)
    end
  end
  
  context "search form" do
    it "offers future years but defaults to the current year and month" do
      today = Date.today
      visit events_path

      years = page.all("select#year option").map(&:text)
      expect(years.first).to eq (today.year + 2).to_s
      expect(years).to include (today.year + 1).to_s
      expect(years.last).to eq "2005"

      expect(page).to have_select("year", selected: today.year.to_s)
      expect(page).to have_select("month", selected: I18n.t("month.m#{today.strftime('%m')}"))
    end
  end
end
