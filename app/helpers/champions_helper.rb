module ChampionsHelper
  def champion_category_menu(selected, default="champion.category.any")
    cats = Champion::CATEGORIES.map { |cat| [champion_category(cat), cat] }
    cats.unshift [t(default), ""]
    options_for_select(cats, selected)
  end

  def champion_category(cat)
    t("champion.category.#{cat}")
  end
end
