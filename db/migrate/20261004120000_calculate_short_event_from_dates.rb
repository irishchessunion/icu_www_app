# short_event is now set from an event's dates (see Event::MAX_SHORT_EVENT_DAYS), so recalculate it for
# existing events. Every row must match, otherwise editing an ended event would count as changing short_event.
class CalculateShortEventFromDates < ActiveRecord::Migration[8.1]
  def up
    execute "UPDATE events SET short_event = (DATEDIFF(end_date, start_date) + 1 <= 13) WHERE start_date IS NOT NULL AND end_date IS NOT NULL"
  end

  def down
    # Nothing to undo: the previous values were set by hand and weren't kept
  end
end
