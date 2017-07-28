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

  def user_menu(selected_user_id)
    options_for_select(User.vips.by_name.map { |user| [user.name, user.id] }, selected_user_id)
  end

  # @param entry_item [Item::Entry]
  def event_entry_item_description(entry_item)
    desc = ""
    if entry_item.player_id
      if entry_item.player.latest_rating
        desc = "#{entry_item.player.latest_rating} "
      elsif entry_item.player.legacy_rating
        desc = "#{entry_item.player.legacy_rating} "
      end
      desc += "#{entry_item.player.player_title} " if entry_item.player.player_title
      desc += entry_item.player.name
    else
      desc = "Unknown Player"
    end
    desc
  end


  # @param fee_entry [Fee::Entry]
  def event_entry_fee_description(fee_entry)
    descr = fee_entry.name
    extras = []
    if fee_entry.sections.present? && fee_entry.event && fee_entry.event.section_names.size > 1
      extras << "Sections: #{fee_entry.sections}"
    end
    if fee_entry.min_age.present?
      extras << "aged #{fee_entry.min_age} or over"
    end
    if fee_entry.max_age.present?
      extras << "aged #{fee_entry.max_age} or under"
    end

    if fee_entry.min_rating.present?
      extras << "rated >= #{fee_entry.min_rating}"
    end

    if fee_entry.max_rating.present?
      extras << "rated <= #{fee_entry.max_rating}"
    end

    "#{descr} #{extras.join(', ')}"
  end
end
