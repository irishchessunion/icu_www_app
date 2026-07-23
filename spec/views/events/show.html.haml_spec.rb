require 'rails_helper'

RSpec.describe "events/show", type: :view do
  let!(:event) do
    event = build(
      :event,
      name: "Inishbofin Congress",
      location: "Inishbofin, Connemara, Co. Galway",
      start_date: Date.today + 30,
      end_date: Date.today + 33,
      note: "The best Irish tournament.",
      contact: "Oscar Wilde",
      email: "oscar.wilde1854@example.com",
      phone: "0871234567",
      prize_fund: 3250,
      url: "https://www.inishbofinchess.com",
      pairings_url: "http://chess-results.com/1234",
      results_url: "http://results.inishbofinchess.com",
      report_url: "http://www.icu.ie/a/123",
      live_games_url: "https://livechesscloud.com/xyz",
      live_games_url2: "https://lichess.com",
      time_controls: ["classical", "rapid"],
      category: "foreign",
      sections: "open,intermediate,major",
      is_fide_rated: true,
      active: true
    )
    event.save!(validate: false)
    event
  end

  let!(:player) do
    player = build(:player, first_name: "Eavan", last_name: "Boland", latest_rating: 2130)
    player.save!(validate: false)
    player
  end

  let!(:fee_open) do
    fee = build(:entry_fee, event: event, name: "Standard", sections: "open", amount: 50.0)
    fee.save!(validate: false)
    fee
  end

  let!(:fee_all) do
    fee = build(:entry_fee, event: event, name: "U18", sections: "open,intermediate,major", amount: 35.0, max_age: 18)
    fee.save!(validate: false)
    fee
  end

  let!(:paid_entry) do
    item = build(:paid_entry_item, fee: fee_open, player: player)
    item.save!(validate: false)
    item
  end

  before do
    assign(:event, event)
    allow(view).to receive(:can?).and_return(false)
    assign(:on_sale_fees, [])
    assign(:paid_entries, [paid_entry])
    assign(:entries_by_section, { nil => [paid_entry] })
    render
  end

  describe "panel" do
    it "displays the event name" do
      expect(rendered).to have_selector("h2", text: "Inishbofin Congress")
    end

    it "displays the event location" do
      expect(rendered).to have_selector(".show-panel", text: "Inishbofin, Connemara, Co. Galway")
    end

    it "displays time controls" do
      expect(rendered).to have_selector(".show-panel", text: I18n.t("event.time_controls.classical"))
    end

    it "displays the category" do
      expect(rendered).to have_selector(".show-panel", text: I18n.t("event.category.foreign"))
    end

    it "displays the prize fund" do
      expect(rendered).to have_selector(".show-panel", text: "€3,250")
    end

    it "displays the website button" do
      expect(rendered).to have_link("Website", href: "https://www.inishbofinchess.com")
    end
  end

  describe "description section" do
    it "renders the note" do
      expect(rendered).to have_selector("section#description", text: "The best Irish tournament.")
    end
  end

  describe "contact section" do
    it "renders contact details" do
      expect(rendered).to have_selector("section#contact", text: "Oscar Wilde")
      expect(rendered).to have_selector("section#contact", text: "0871234567")
    end
  end

  describe "links section" do
    it "renders links" do
      expect(rendered).to have_selector("section#links")
      expect(rendered).to have_link("Pairings", href: "http://chess-results.com/1234")
      expect(rendered).to have_link("Results", href: "http://results.inishbofinchess.com")
    end
  end

  describe "enter section" do
    before do
      assign(:on_sale_fees, [fee_open, fee_all])
      render
    end

    it "renders the enter section with fees" do
      expect(rendered).to have_selector("section#enter")
      expect(rendered).to have_selector("section#enter", text: "Standard")
      expect(rendered).to have_selector("section#enter", text: "U18")
    end

    it "groups fees by section" do
      expect(rendered).to have_selector("section#enter", text: "Open")
      expect(rendered).to have_selector("section#enter", text: "Intermediate")
      expect(rendered).to have_selector("section#enter", text: "Major")
    end
  end

  describe "entries section" do
    it "renders the entries section with the player" do
      expect(rendered).to have_selector("section#entries")
      expect(rendered).to have_selector("section#entries", text: "Eavan Boland")
    end
  end

  describe "admin section" do
    before do
      allow(view).to receive(:can?).with(:read, event).and_return(true)
      allow(view).to receive(:can?).with(:update, event).and_return(true)
      render
    end

    it "renders when user has read access" do
      expect(rendered).to have_selector("section.show-admin")
    end
  end
end