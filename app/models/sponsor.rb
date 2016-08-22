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
  validates_presence_of :name, :weblink, :weight
  validates :contact_email, email: true, allow_nil: true, allow_blank: true
  validates :valid_until, date: { on_or_after: :today }, allow_nil: true
  before_create :init_clicks

  scope :active, -> { where("valid_until is null or valid_until >= ?", Date.today) }

  def self.random_pair
    active_sponsors = active.to_a
    if active_sponsors.length < 2
      return active_sponsors
    end

    first = weighted_random(active_sponsors)
    active_sponsors.delete(first)
    second = weighted_random(active_sponsors)
    [first, second]
  end

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

  def record_eyeball
    increment!(:eyeballs)
  end

  private

  def init_clicks
    self.clicks ||= 0
    self.eyeballs ||= 0
  end
end
