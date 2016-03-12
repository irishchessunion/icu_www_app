class Sponsor < ActiveRecord::Base
  include Journalable
  include Normalizable
  include Pageable
  include Remarkable

  journalize %w[
    name weblink weight valid_until contact_email contact_name contact_phone notes
    logo_file_name logo_content_type logo_file_size
  ], "/admin/sponsors/%d"

  has_attached_file :logo, keep_old_files: true

  validates_attachment :logo, content_type: { content_type: /\Aimage\/(#{Image::TYPES})\z/, file_name: /\.(#{Image::TYPES})\z/i }
  validates :logo, presence: true
  validates_presence_of :name, :weblink, :weight
  validates :contact_email, email: true, allow_nil: true, allow_blank: true
  validates :valid_until, date: { on_or_after: :today }, allow_nil: true
  before_create :init_clicks

  scope :active, -> { where("valid_until is null or valid_until >= ?", Date.today) }

  def self.random
    weighted_random(active.to_a)
  end

  def self.weighted_random(weights)
    r = Kernel.rand(weights.map(&:weight).sum)
    accumulated_weight = 0
    weights.each do |sp|
      accumulated_weight += sp.weight
      if accumulated_weight >= r
        return sp
      end
    end
    return weights.last
  end

  def record_click
    increment!(:clicks)
  end

  private

  def init_clicks
    self.clicks ||= 0
  end
end
