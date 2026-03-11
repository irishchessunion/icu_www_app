class EventUser < ApplicationRecord
  belongs_to :event
  belongs_to :user

  validates :event_id, presence: true, uniqueness: { scope: :user_id }
  validates :user_id, presence: true
  validates :role, inclusion: { in: %w[full_access limited_access] }

  scope :full_access, -> { where(role: "full_access") }
  scope :limited_access, -> { where(role: "limited_access") }

  def full_access?
    role == "full_access"
  end

  def limited_access?
    role == "limited_access"
  end
end
