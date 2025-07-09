class Item::Subscription < Item
  validates :start_date, :end_date, presence: true, unless: Proc.new { |i| i.description.match(/life/i) }
  validates :player, presence: true, unless: Proc.new { |s| s.player_data.present? }
  validate :no_duplicates, :valid_player_data

  scope :lifetime_duplicates, ->(player)           { active.where(player_id: player.id, end_date: nil) }
  scope :season_duplicates,   ->(player, end_date) { active.where(player_id: player.id, end_date: end_date) }
  scope :any_duplicates,      ->(player, end_date) { active.where(player_id: player.id).where("end_date = ? OR end_date IS NULL", end_date) }

  def additional_information
    info = []
    if active?
      ticket = season_ticket
      info.push "#{I18n.t('user.ticket', locale: :en)}: #{ticket}" if ticket
    end
    info
  end

  def season
    Season.new("#{start_date.try(:year)} #{end_date.try(:year)}")
  end

  def duplicate_of?(item)
    if type == item.type && fee.years == item.fee.years && player_id.present? && player_id == item.player_id
      I18n.t("item.error.subscription.already_in_cart", member: player.name(id: true), season: fee.years)
    elsif player_data.present? && new_player == item.new_player
      I18n.t("item.error.subscription.new_player_duplicate.cart", name: new_player.name, dob: new_player.dob.to_s)
    else
      false
    end
  end

  def subscription_type
    description.sub(/ ICU Subscription \d{4}-\d{2}\z/, "")
  end

  def self.new_lifetime_member(player_id)
    player = Player.where(id: player_id).first
    raise ArgumentError, "invalid ICU ID" unless not player.nil? # checks if the ICU ID is valid
      
    sub = Item::Subscription.where(["player_id = ? AND description LIKE 'Lifetime%'", player_id]).first
    raise ArgumentError, "already a lifetime member" unless sub.nil? # checks if the player is already a lifetime member

    lifetime_sub = Item::Subscription.new(description: "Lifetime ICU Subscription", player_id: player_id, status: "paid", source: "www1", payment_method: "free")
    lifetime_sub.save!
  end

  private

  def no_duplicates
    if player && new_record?
      if end_date.present? && self.class.season_duplicates(player, end_date).count > 0
        errors.add(:base, I18n.t("item.error.subscription.already_exists", member: player.name(id: true), season: season.to_s))
      elsif self.class.lifetime_duplicates(player).count > 0
        errors.add(:base, I18n.t("item.error.subscription.lifetime_exists", member: player.name(id: true)))
      end
    end
  end

  def valid_player_data
    if player_data.present?
      new_player = NewPlayer.from_json(player_data)
      if new_player
        player = new_player.to_player
        unless player.valid?
          Failure.log("InvalidNewPlayer", player_data: player_data, errors: player.errors.to_a.join(', '))
          errors.add(:base, I18n.t("errors.alerts.application"))
        end
      else
        Failure.log("InvalidPlayerData", player_data: player_data)
        errors.add(:base, I18n.t("errors.alerts.application"))
      end
    end
  end

  def season_ticket
    t = SeasonTicket.new(player.id, end_date.at_end_of_year)
    raise t.error if t.error
    t.to_s
  rescue => e
    Failure.log("SubscriptionSeasonTicket", cart: cart.present? && cart.id, player: player.present? && player.id, end_date: end_date.present? && end_date.to_s, error: e.message, exception: e.class.to_s)
    nil
  end
end
