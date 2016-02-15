class Result < ActiveRecord::Base
  include Journalable
  include Normalizable
  include Pageable

  journalize %w[competition player1 player2 score active], "/results/%d"

  belongs_to :reporter, class_name: 'User'

  scope :active, -> { where(active: true) }
  scope :include_reporter, -> { includes(:reporter) }
  scope :ordered, -> { order('created_at DESC') }

  scope :recent, -> { active.include_reporter.ordered.limit(5) }
end
