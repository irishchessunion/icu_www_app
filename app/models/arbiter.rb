class Arbiter < ApplicationRecord
  include Pageable
  include Journalable
  include Normalizable
  journalize %w[player_id email phone location level date_of_qualification active], "/admin/arbiters/%d"

  belongs_to :player

  LEVELS = %w[club national international]

  scope :active,          -> { where(active: true) }
  scope :ordered,         -> { joins(:player).order("players.last_name, players.first_name") }
  scope :include_players, -> { includes(:player) }

  validates :player_id,           presence: true, uniqueness: true
  validates :level,               inclusion: { in: LEVELS }
  validates :date_of_qualification, presence: true

  before_validation :normalize_attributes

  private

  def normalize_attributes
    normalize_blanks(:email, :phone, :location)
  end
end
