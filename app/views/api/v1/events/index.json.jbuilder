json.page @page
json.per_page @per_page
json.total @total
json.total_pages (@total.to_f / @per_page).ceil
json.events @events do |event|
  json.external_id "ICU-EVENT-#{event.id}"
  json.name event.name
  json.start_date event.start_date
  json.end_date event.end_date
  json.country_code "IRL"
  json.latitude event.lat&.to_f
  json.longitude event.long&.to_f
  json.address event.location
  json.tournament_type event.tournament_type
  json.format event.time_controls.blank? ? "classical" : event.time_controls.first
  json.time_control event.time_control_details.to_s
  json.is_fide_rated event.is_fide_rated
  json.is_nationally_rated event.icu_rated
  json.max_participants event.max_participants
  json.registration_deadline event.registration_deadline
  json.external_registration_url event_url(event, host: "www.icu.ie", protocol: "https")
  json.description event.note_html.presence
  json.contact event.contact
  json.sections event.fees_by_section do |name, fees|
    json.name name
    json.fees fees do |fee|
      json.name fee.name
      json.amount fee.amount.to_f
      json.currency "EUR"
      json.discounted_amount fee.discounted_amount&.to_f
      json.discount_deadline fee.discount_deadline
      json.rating_min fee.min_rating
      json.rating_max fee.max_rating
      json.age_min fee.min_age
      json.age_max fee.max_age
      json.age_ref_date fee.age_ref_date
      json.sale_start fee.sale_start
      json.sale_end fee.sale_end
    end
  end
end
