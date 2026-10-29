module StructuredDataHelper
  def club_structured_data(club)
    url = club_url(club, host: "www.icu.ie", protocol: "https")
    address = {
      "@type" => "PostalAddress",
      "streetAddress" => club.address,
      "addressLocality" => club.city,
      "addressRegion" => t("ireland.co.#{club.county}"),
      "postalCode" => club.eircode,
    }.compact_blank

    {
      "@context" => "https://schema.org",
      "@type" => "SportsOrganization",
      "@id" => url,
      "name" => club.name,
      "url" => url,
      "sameAs" => club.web,
      "sport" => "Chess",
      "description" => structured_data_description(club, club.notes),
      "email" => club.email,
      "telephone" => club.phone,
      "location" => {
        "@type" => "Place",
        "address" => address,
        "geo" => structured_data_geo(club),
      }.compact_blank,
    }.compact_blank
  end

  def event_structured_data(event)
    url = event_url(event, host: "www.icu.ie", protocol: "https")

    {
      "@context" => "https://schema.org",
      "@type" => "SportsEvent",
      "@id" => url,
      "name" => event.name,
      "url" => url,
      "sameAs" => event.url,
      "sport" => "Chess",
      "description" => structured_data_description(event, event.note),
      "startDate" => event.start_date.iso8601,
      "endDate" => event.end_date.iso8601,
      "maximumAttendeeCapacity" => event.max_participants,
      "location" => {
        "@type" => "Place",
        "name" => event.location,
        "address" => event.location,
        "geo" => structured_data_geo(event),
      }.compact_blank,
    }.compact_blank
  end

  private

  def structured_data_description(record, content)
    # Omit non-text shortcuts before Markdown can expose their generated markup.
    content = content.to_s.gsub(/\[(?:EMA|FEN|IMG):[^\]]*\]/, " ")
    html = record.render_wysiwyg_content(record.expand_all(content))
    fragment = Nokogiri::HTML.fragment(html)
    fragment.css("script, style").remove
    fragment.css("br, p, div, li, h1, h2, h3, h4, h5, h6, blockquote, tr").each do |node|
      node.add_next_sibling(" ")
    end
    shortcuts = Regexp.union(Expandable::EXPANDABLE.keys + Expandable::SPECIAL.keys)
    fragment.text.gsub(/\[(?:#{shortcuts}):[^\]]*\]/, " ").squish.presence
  end

  def structured_data_geo(record)
    return unless record.geocodes?

    {
      "@type" => "GeoCoordinates",
      "latitude" => record.lat.to_f,
      "longitude" => record.long.to_f,
    }
  end
end
