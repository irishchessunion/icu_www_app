require 'rails_helper'

RSpec.describe "events/index", type: :view do
  let!(:event1) { create(:event, name: "Dublin Rapid", start_date: Date.today + 10, end_date: Date.today + 10, time_controls: ["rapid"], category: "junior", active: true) }
  let!(:event2) { create(:event, name: "Cork Open", start_date: Date.today + 10, end_date: Date.today + 12, time_controls: ["classical", "blitz"], category: "irish", active: true) }

  before do
    assign(:events, Event.search({}, "/events"))
    assign(:map_events, Event.search({}, "/events"))
    assign(:center, [53.45, -7.95])
    assign(:zoom, 6.4)
    allow(view).to receive(:can?).with(:create, Event).and_return(true)
    render
  end

  it "displays the page title" do
    expect(rendered).to have_selector("h2", text: I18n.t('event.upcoming'))
  end

  it "displays a result with the event name and link" do
    expect(rendered).to have_link("Dublin Rapid", href: event_path(event1))
  end

  it "displays a result with time controls" do
    expect(rendered).to include(I18n.t("event.time_controls.rapid"))
  end

  it "displays a result with a category" do
    expect(rendered).to include(I18n.t("event.category.junior"))
  end

  it "renders the search panel partial" do
    expect(rendered).to have_selector("section.full-width.events-search")
  end

  it "renders the is_fide_rated checkbox" do
    expect(rendered).to have_selector("#is_fide_rated")
  end

  it "renders the search field" do
    expect(rendered).to have_selector("#search")
  end

  it "renders the search button" do
    expect(rendered).to have_button("Search")
  end

  it "renders the map" do
    expect(rendered).to have_selector("#map-canvas")
  end

end
