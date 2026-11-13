class Officer < ApplicationRecord
  include Pageable # for journal items, not officers
  include Journalable
  journalize %w[email executive name phone player_id rank role], "/admin/officers/%d"

  belongs_to :player

  before_validation :normalize_attributes

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(rank: :asc, name: :asc) }
  scope :include_players, -> { includes(:player) }

  validates :name, presence: true, length: { maximum: 50 }, uniqueness: true
  validates :rank, numericality: { integer_only: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 100 }
  # Only the original officers have a role, an internal key which some pages use to find them (e.g. "women").
  validates :role, length: { maximum: 20 }, uniqueness: true, allow_nil: true
  validates :email, email: true, allow_nil: true
  validates :phone, length: { maximum: 30 }, allow_nil: true

  def html_email
    return unless email
    link = %Q[<a href="mailto:#{email}">#{email}</a>]
    "<script>liame(#{link.obscure})</script>".html_safe
  end

  private

  def normalize_attributes
    self.name = name.to_s.squish.presence
    self.role = role.presence
    self.email = email.to_s.strip.presence
    self.phone = phone.to_s.squish.presence
  end
end
