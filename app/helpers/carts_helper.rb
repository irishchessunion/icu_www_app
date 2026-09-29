module CartsHelper
  def euros(amount, precision: 2)
    number_to_currency(amount, precision: precision, unit: "€")
  end

  def cart_status_menu(selected, default="any")
    statuses = Cart::STATUSES.map { |s| [t("shop.payment.status.#{s}"), s] }
    statuses.unshift [t("inactive"), "inactive"]
    statuses.unshift [t("active"), "active"]
    statuses.unshift [t(default), ""]
    options_for_select(statuses, selected)
  end

  # Prefilled sign-up link for a newly subscribed member who doesn't yet have a user account.
  def sign_up_link(item, cart)
    return unless item.is_a?(Item::Subscription) && item.active?
    player = item.player
    return unless player && player.users.none?
    ticket = item.season_ticket
    return unless ticket
    email = [player.email, cart.confirmation_email].find { |e| e.present? && !User.exists?(email: e) }
    sign_up_url({ player_id: player.id, ticket: ticket, email: email }.compact)
  end
end
