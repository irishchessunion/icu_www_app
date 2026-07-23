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
    it "shows the admin panel and changelog to the event creator" do
      login event.user
      visit event_path(event)
      expect(page).to have_link("Manage Event")
      expect(page).to have_button("View changelog")
    end

    it "hides the admin panel from guests" do
      visit event_path(event)
      expect(page).not_to have_link("Manage Event")
      expect(page).not_to have_button("View changelog")
    end
  end
end