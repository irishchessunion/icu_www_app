module ClubsHelper
  def club_county_menu(selected, default="ireland.co.any")
    counties = Ireland.counties.map { |c| [t("ireland.co.#{c}"), c] }
    counties.unshift [t(default), ""]
    options_for_select(counties, selected)
  end

  def club_menu(selected, opt={})
    clubs = Club.all.map { |c| [c.name, c.id] }
    clubs.unshift [t("player.no_club"), 0] if opt[:none]
    clubs.unshift [t("player.any_club"), ""] if opt[:any]
    options_for_select(clubs, selected)
  end

  def club_province_menu(selected, default="ireland.prov.any")
    provinces = Ireland.provinces.map { |p| [t("ireland.prov.#{p}"), p] }
    provinces.unshift [t(default), ""]
    options_for_select(provinces, selected)
  end

  def club_junior_menu(selected, default="club.juniors.any")
    junior_options = %w(junior_only has_junior_section).map { |p| [t("club.juniors.#{p}"), p] }
    junior_options.unshift [t(default), ""]
    options_for_select(junior_options, selected)
  end

  def google_maps_search(club)
    "https://www.google.com/maps/search/?api=1&query=#{club.eircode}"
  end
end
