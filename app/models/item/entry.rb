class Item::Entry < Item
  validates :start_date, :end_date, presence: true
  validates :player, presence: true, unless: Proc.new { |e| e.player_data.present? }
  validate :membership_check
  validate :no_duplicates
  belongs_to :fee_entry, class_name: 'Fee::Entry', foreign_key: :fee_id


  scope :any_duplicates, ->(fee, player) { active.where(fee_id: fee.id).where(player_id: player.id) }

  def duplicate_of?(item)
    if type == item.type && fee_id == item.fee_id && same_player?(item)
      I18n.t("item.error.entry.already_in_cart", member: player_name)
    else
      false
    end
  end
  
  def season
    Season.new(start_date || created_at.to_date)
  end

  # @return [Array<String>] The sections this entry can be moved to: all of the event's sections, not just its fee's.
  def movable_sections
    fee.event&.section_names.presence || fee.section_names
  end

  # Sections this entry could be moved to where none of the event's entry fees for that section match
  # what was paid for this entry, mapped to the fees for that section (empty if no fee covers it).
  # @return [Hash{String => Array<Fee::Entry>}]
  def sections_with_different_fees
    return {} unless fee.event
    fees = fee.event.fee_entries.to_a
    movable_sections.each_with_object({}) do |name, different|
      next if name == section || covers_section?(fee, name)
      section_fees = fees.select { |f| covers_section?(f, name) }
      next if section_fees.any? { |f| [f.amount, f.discounted_amount].compact.include?(cost) }
      different[name] = section_fees
    end
  end

  # A player from outside Ireland who isn't a member gets the overseas subscription added with their entry.
  # @return [Item::Subscription, nil] An unsaved subscription for the entry's cart, if one is needed.
  def overseas_subscription
    subscription_fee = fee&.overseas_subscription
    return unless subscription_fee && missing_subscription?
    fed = player ? player.fed : new_player&.fed
    return if fed.blank? || fed == "IRL"
    Item::Subscription.new(fee: subscription_fee, player: player, player_data: (player_data unless player), cart: cart)
  end

  # Whether the event needs a subscription that the player doesn't have, paid or waiting in the same cart
  def missing_subscription?
    return false unless fee&.event&.subscription_required
    return false if player&.is_subscribed?(true)
    return true unless cart_id
    Item::Subscription.where(cart_id: cart_id).none? { |s| same_player?(s) }
  end

  # @return [String, nil] An error message if this player has already paid for this entry.
  def paid_duplicate_error
    return unless [player, fee].all?(&:present?)
    return unless self.class.any_duplicates(fee, player).where.not(id: id).exists?
    I18n.t("item.error.entry.already_entered", member: player.name(id: true))
  end

  private

  # A fee with no sections of its own doesn't cover any, the same as on the event page's list of fees.
  def covers_section?(entry_fee, name)
    entry_fee.section_names.include?(name)
  end

  def membership_check
    errors.add(:base, I18n.t("item.error.entry.no_subscription", member: player_name)) if missing_subscription?
  end

  def same_player?(item)
    player_id ? player_id == item.player_id : player_data.present? && new_player == item.new_player
  end

  def no_duplicates
    return unless new_record?
    error = paid_duplicate_error
    errors.add(:base, error) if error
  end
end
