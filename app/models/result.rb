class Result < ActiveRecord::Base
  include Expandable
  include Journalable
  include Normalizable
  include Remarkable
  include Pageable

  journalize %w[competition player1 player2 score active], "/results/%d"

  belongs_to :reporter, class_name: 'User'

  scope :active, -> { where(active: true) }
  scope :include_reporter, -> { includes(:reporter) }
  scope :ordered, -> { order('created_at DESC') }

  scope :recent, -> { active.include_reporter.ordered.limit(5) }

  before_create :make_active

  validate :only_allowed_reporters, on: :create
  validates_presence_of :competition, :player1, :player2, :score, if: -> {message.blank?}

  def reporter_name
    reporter.player.initials
  end

  def full_message
    if message.present?
      expand_all(message).html_safe
    else
      "#{competition}: #{player1} #{score} #{player2}"
    end
  end

  # Bans the reporter and deactivates the result
  def ban
    update(active: false)
    reporter.update(disallow_reporting: true)
  end

  private

  def only_allowed_reporters
    if !reporter || reporter.disallow_reporting?
      errors.add(:base, 'You are not allowed to report results')
    end
  end

  def make_active
    self.active = true
  end
end
