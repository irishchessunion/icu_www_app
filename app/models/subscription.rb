class Subscription < ActiveRecord::Base
  include Cartable

  belongs_to :player
  belongs_to :subscription_fee

  CATEGORIES = %w[standard over_65 under_18 under_12 unemployed new_under_18 lifetime]

  validates :player_id, numericality: { only_integer: true, greater_than: 0 }
  validates :subscription_fee_id, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :category, inclusion: { in: CATEGORIES }
  validates :cost, numericality: { greater_than_or_equal: 0.0 }

  validate :valid_season_desc, :no_duplicates, :right_age

  def season
    @season ||= Season.new(season_desc)
  end

  def description
    desc = []
    desc << I18n.t("fee.type.subscription")
    desc << season_desc unless category == "lifetime"
    desc << I18n.t("fee.subscription.category.#{category}")
    desc.join(" ")
  end

  def duplicate_of?(sub, add_error=false)
    if sub.player_id == player_id && sub.season_desc == season_desc
      errors.add(:base, I18n.t("fee.subscription.error.already_in_cart", member: player.name(id: true))) if add_error
      true
    else
      false
    end
  end

  private

  def valid_season_desc
    if season_desc.blank?
      self.season_desc = nil
    else
      season = Season.new(season_desc)
      if season.error
        errors.add(:season_desc, season.error)
      elsif
        self.season_desc = season.desc
      end
    end
  end

  def no_duplicates
    if player
      if season_desc && Subscription.where(active: true, player_id: player.id, season_desc: season_desc).count > 0
        errors.add(:base, I18n.t("fee.subscription.error.already_exists", member: player.name(id: true), season: season_desc))
      elsif Subscription.where(active: true, player_id: player.id, season_desc: nil).count > 0
        errors.add(:base, I18n.t("fee.subscription.error.lifetime_exists", member: player.name(id: true)))
      end
    end
  end

  def right_age
    return unless category.match(/(under|over)_\d+/)
    return unless player && player.dob.present? && subscription_fee && subscription_fee.age_ref_date.present?
    age = player.age(subscription_fee.age_ref_date)
    error, limit =
    case
    when age > 12 && category == "under_12"       then ["too_old", 12]
    when age < 65 && category == "over_65"        then ["too_young", 65]
    when age > 18 && category.match(/under_18\z/) then ["too_old", 18]
    end
    if error
      errors.add(:base, I18n.t("fee.subscription.error.#{error}", member: player.name(id: true), limit: limit, date: subscription_fee.age_ref_date.to_s))
    end
  end
end