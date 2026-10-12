module OfficersHelper
  def officer_menu(selected)
    officers = Officer.ordered.active.all.map { |o| [o.name, o.id] }
    officers.unshift [t("none"), ""]
    options_for_select(officers, selected)
  end
end
