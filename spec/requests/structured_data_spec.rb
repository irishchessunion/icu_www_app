require 'rails_helper'

describe "Public page structured data", type: :request do
  def structured_data(path)
    get path
    expect(response).to have_http_status(:ok)
    scripts = Nokogiri::HTML(response.body).css('head script[type="application/ld+json"]')
    expect(scripts.size).to eq 1
    JSON.parse(scripts.first.text)
  end

  it "describes clubs as sports organizations with their public details" do
    club = create(:club, web: "https://bangor.example.com", lat: 54.66, long: -5.67,
      notes: "All **abilities** welcome.")
    data = structured_data(club_path(club))

    expect(data).to include(
      "@context" => "https://schema.org",
      "@type" => "SportsOrganization",
      "name" => club.name,
      "url" => "https://www.icu.ie/clubs/#{club.id}",
      "sameAs" => club.web,
      "description" => "All abilities welcome.",
      "email" => club.email,
      "telephone" => club.phone
    )
    expect(data["location"]["address"]).to include("@type" => "PostalAddress", "addressLocality" => club.city)
    expect(data["location"]["geo"]).to include("latitude" => 54.66, "longitude" => -5.67)
  end

  it "describes sports events with dates, venue and a plain-text description" do
    event = create(:event, lat: 53.259, long: -9.077, max_participants: 120,
      markdown: false, note: "<p>Six <strong>rounds</strong>.</p><p>Enter &amp; play.</p>")
    data = structured_data(event_path(event))

    expect(data).to include(
      "@type" => "SportsEvent",
      "name" => event.name,
      "url" => "https://www.icu.ie/events/#{event.id}",
      "description" => "Six rounds. Enter & play.",
      "startDate" => event.start_date.iso8601,
      "endDate" => event.end_date.iso8601,
      "maximumAttendeeCapacity" => 120
    )
    expect(data["location"]).to include("@type" => "Place", "address" => event.location)
    expect(data["location"]["geo"]).to include("latitude" => 53.259, "longitude" => -9.077)
  end

  it "omits missing optional details and safely embeds names" do
    event = create(:event, name: '</script><script id="injected">1</script>')
    data = structured_data(event_path(event))

    expect(data["name"]).to eq event.name
    expect(data.keys & %w[sameAs description maximumAttendeeCapacity]).to be_empty
    expect(data["location"]).not_to have_key("geo")
    expect(Nokogiri::HTML(response.body).at_css("script#injected")).to be_nil
  end

  it "keeps shortcut link text without shortcut codes, diagrams or email JavaScript" do
    article = create(:article, title: "Club news")
    text = "[ART:#{article.id}] [EXL:https://example.com:Website] [RTN:123:Ratings] " \
      "[EMA:secretary@icu.ie:Secretary] [FEN:k7/8/8/8/8/8/8/7K w] [ART:0] &#91;IMG:123&#93;"

    [create(:club, notes: text), create(:event, note: text)].each do |record|
      [true, false].each do |markdown|
        record.update_column(:markdown, markdown)
        expect(structured_data(polymorphic_path(record))["description"]).to eq "Club news Website Ratings"
      end
    end
  end
end
