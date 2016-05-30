module EventsHelper
  def event_category_menu(selected, default=nil)
    cats = Event::CATEGORIES.map { |cat| [t("event.category.#{cat}"), cat] }
    cats.unshift([t(default), ""]) if default
    options_for_select(cats, selected)
  end

  def event_month_menu(selected)
    months = (1..12).map { |m| m = "%02d" % m; [t("month.m#{m}"), m] }
    options_for_select(months, selected)
  end

  def event_year_menu(selected)
    years = (2005..Date.today.year).to_a.reverse.map { |y| [y, y] }
    options_for_select(years, selected)
  end

  def events_menu(selected_event_id, events)
    options_for_select(([Event.new(name: '')] + events).map { |event| [event.name, event.id] }, selected_event_id)
  end

  # @param entry_item [Item::Entry]
  def event_entry_item_description(entry_item)
    if entry_item.player_id
      desc = entry_item.player.name
      if entry_item.player.latest_rating
        desc += " (#{entry_item.player.latest_rating})"
      elsif entry_item.player.legacy_rating
        desc += " (#{entry_item.player.legacy_rating})"
      end
    else
      desc = "Unknown Player"
    end
    desc
  end
end
