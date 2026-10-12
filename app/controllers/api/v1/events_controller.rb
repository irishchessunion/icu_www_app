# Lists events for third parties who want to advertise them.
#
# Parameters (all optional):
#   from          - YYYY-MM-DD, only events that end on or after this date (default: today)
#   to            - YYYY-MM-DD, only events that start on or before this date
#   category      - one or more of Event::CATEGORIES, separated by commas (default: DEFAULT_CATEGORIES)
#   updated_since - ISO 8601 date or time, only events changed at or after it
#   page          - which page of results (default: 1)
#   per_page      - events per page (default: 50, maximum: 100)
class Api::V1::EventsController < Api::BaseController
  requires_permission "events"

  # Events abroad are left out unless asked for, as every event is listed as being in Ireland.
  DEFAULT_CATEGORIES = Event::CATEGORIES - %w[foreign junint]
  DEFAULT_PER_PAGE = 50
  MAX_PER_PAGE = 100

  def index
    from = date_param(:from) || Date.today
    to = date_param(:to)
    bad_request("to can't be before from") if to && to < from

    events = Event.active.where("end_date >= ?", from)
    events = events.where("start_date <= ?", to) if to

    events = events.where(category: list_param(:category, Event::CATEGORIES) || DEFAULT_CATEGORIES)

    if (time = time_param(:updated_since))
      events = events.where("events.updated_at >= ?", time)
    end

    @page = integer_param(:page, min: 1) || 1
    @per_page = integer_param(:per_page, min: 1, max: MAX_PER_PAGE) || DEFAULT_PER_PAGE
    @total = events.count
    # The id makes the order, and so the pages, stable for events with the same dates and name.
    @events = events.includes(:fee_entries).ordered.order(:id).offset((@page - 1) * @per_page).limit(@per_page)
  end
end
