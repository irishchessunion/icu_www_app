class Item::Entry < Item
  validates :start_date, :end_date, :player, presence: true
  validate :membership_check
  validate :no_duplicates
  belongs_to :fee_entry, class_name: 'Fee::Entry', foreign_key: :fee_id


  scope :any_duplicates, ->(fee, player) { active.where(fee_id: fee.id).where(player_id: player.id) }

  def duplicate_of?(item)
    if type == item.type && fee_id == item.fee_id && player_id == item.player_id
      I18n.t("item.error.entry.already_in_cart", member: player.name(id: true))
    else
      false
    end
  end
  
  def season
    Season.new(start_date || created_at.to_date)
  end

  private

  def membership_check
    if fee.event&.subscription_required && !player.is_subscribed?(true)
      errors.add(:base, I18n.t("item.error.entry.no_subscription", member: player.name(id: true)))
    end
  end

  def no_duplicates
    if new_record? && [player, fee].all?(&:present?)
      if self.class.any_duplicates(fee, player).count > 0
        errors.add(:base, I18n.t("item.error.entry.already_entered", member: player.name(id: true)))
      end
    end
  end
end
