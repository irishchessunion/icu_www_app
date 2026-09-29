class ClubMeeting < ApplicationRecord
  DAYS_OF_WEEK = %w[monday tuesday wednesday thursday friday saturday sunday].freeze
  AUDIENCES = %w[open juniors_only women_only].freeze

  belongs_to :club

  validates :club, presence: true
  validates :day_of_week, inclusion: { in: DAYS_OF_WEEK }
  validates :start_time, presence: true
  validates :audience, inclusion: { in: AUDIENCES }
  validates :welcomes_juniors, inclusion: { in: [true, false] }
end
