json.array! @events do |event|
  json.external_id "ICU-EVENT-#{event.id}"
  json.name event.name
  json.start_date event.start_date
  json.end_date event.end_date
  json.country_code "IRL"
  json.latitude event.lat
  json.longitude event.long
  json.address event.location
  json.tournament_type "swiss"
  json.format event.time_controls.blank? ? "classical" : event.time_controls.first
  json.time_control event.time_controls
  json.is_fide_rated event.is_fide_rated
  json.is_nationally_rated true
  json.external_registration_url "https://icu.ie/events/#{event.id}"
  json.description event.note
  json.contact event.contact
  json.image event.url
end
