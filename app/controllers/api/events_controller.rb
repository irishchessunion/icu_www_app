class Api::EventsController < Api::BaseController
  requires_permission "events"

  def index
    @events = Event.active.ordered

    if (date = parse_date(params[:start_date]))
      @events = @events.where("end_date >= ?", date)
    end

    if (date = parse_date(params[:end_date]))
      @events = @events.where("start_date <= ?", date)
    end
  end

  private

  # @param value [String, nil] a date in YYYY-MM-DD format
  # @return [Date, nil]
  def parse_date(value)
    return nil if value.blank?
    Date.strptime(value.to_s, "%Y-%m-%d")
  rescue ArgumentError
    nil
  end
end
