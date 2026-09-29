module CartsHelper
  def euros(amount, precision: 2)
    number_to_currency(amount, precision: precision, unit: "€")
  end

  # Extra lines shown under each item in payment receipts to help admins and treasurers identify records.
  def item_reference_lines(item)
    lines = []
    if item.is_a?(Item::Entry) && (event = item.fee&.event)
      dates = [event.start_date, event.end_date].compact.uniq.map(&:to_s).join(" to ")
      lines.push ["Event: #{event.name}", dates.presence].compact.join(", ")
      lines.push event_url(event)
    end
    lines.push "Fee ID: #{item.fee_id || 'none'}, Item ID: #{item.id}"
    lines
  end

  def cart_status_menu(selected, default="any")
    statuses = Cart::STATUSES.map { |s| [t("shop.payment.status.#{s}"), s] }
    statuses.unshift [t("inactive"), "inactive"]
    statuses.unshift [t("active"), "active"]
    statuses.unshift [t(default), ""]
    options_for_select(statuses, selected)
  end
end
