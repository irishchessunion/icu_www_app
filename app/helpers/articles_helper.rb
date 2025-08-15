module ArticlesHelper
  def category_menu(selected, default="article.category.any")
    cats = CategoriesOwner::CATEGORIES.map { |cat| [t("article.category.#{cat}"), cat] }
    cats.unshift [t(default), ""] if default
    options_for_select(cats, selected)
  end

  def categories_menu(selected)
    cats = CategoriesOwner::CATEGORIES.map { |cat| [t("article.category.#{cat}"), cat] }
    options_for_select(cats, selected)
  end

  def article_user_menu(selected)
    players = Player.joins(users: :articles).order(:last_name, :first_name).select("DISTINCT players.*").all.map{ |p| [p.name(reversed: true), p.id] }
    players.unshift [t("user.any_editor"), ""]
    options_for_select(players, selected)
  end
end
