module FeesHelper
  def fee_type_menu(selected)
    types = Fee::TYPES.map do |type|
      [t("fee.type.#{Fee.subtype(type)}"), type]
    end
    types.unshift [t("all"), ""]
    options_for_select(types, selected)
  end

  def fee_sale_menu(selected)
    sales = [
      ["In sale period", "current"],
      ["Sale finished", "past"],
      ["Sale not started", "future"],
      ["All", "all"],
    ]
    options_for_select(sales, selected)
  end

  def fee_event_link(fee)
    if fee.type == "Fee::Entry" && fee.event_id.present?
      link_to fee.event.name, event_path(fee.event)
    elsif fee.type == "Fee::Subscription"
      "Subscription"
    elsif fee.type == "Fee::Other"
      "Other"
    else
      "No idea"
    end
  end
end
