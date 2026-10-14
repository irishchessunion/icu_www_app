class Officer < ApplicationRecord
  include Pageable # for journal items, not officers
  include Journalable
  journalize %w[executive name player_id rank role], "/admin/officers/%d"

  belongs_to :player
  has_many :relays

  before_validation :normalize_attributes

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(rank: :asc, name: :asc) }
  scope :include_players, -> { includes(:player) }

  validates :name, presence: true, length: { maximum: 50 }, uniqueness: true
  validates :rank, numericality: { integer_only: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 100 }
  # Only the original officers have a role, an internal key which some pages use to find them (e.g. "women").
  validates :role, length: { maximum: 20 }, uniqueness: true, allow_nil: true

  def emails
    relays.map do |relay|
      if relay.enabled
        relay.from
      else
        relay.forwards
      end
    end.flatten.uniq.sort
  end

  def html_emails
    emails.map do |email|
      link = %Q[<a href="mailto:#{email}">#{email}</a>]
      "<script>liame(#{link.obscure})</script>"
    end.join(", ").html_safe
  end

  private

  def normalize_attributes
    self.name = name.to_s.squish.presence
    self.role = role.presence
  end
end
