require 'rails_helper'

RSpec.describe "events/history", type: :view do
  let!(:event) { create(:event, name: "Dublin Rapid", start_date: Date.today - 10, end_date: Date.today - 10, time_controls: ["rapid"], pairings_url: "http://chess-results.com", report_url: "http://icu.ie/report/123", active: true) }

  before do
    assign(:past_events, Event.search({}, "/events"))
    allow(view).to receive(:can?).and_return(true)
    render
  end

  it "displays the page title" do
    expect(rendered).to have_selector("h2", text: I18n.t('event.history'))
  end

  it "renders a table of past events" do
    expect(rendered).to have_selector("table#results")
    expect(rendered).to have_link("Dublin Rapid", href: event_path(event))
  end

  it "renders report and pairings button links when present" do
    expect(rendered).to have_link("Report", href: "http://icu.ie/report/123")
    expect(rendered).to have_link("Pairings / Results", href: "http://chess-results.com")
  end

end
