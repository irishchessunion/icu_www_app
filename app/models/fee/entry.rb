class Fee::Entry < Fee
  before_validation :default_attributes

  belongs_to :event

  validates :start_date, :end_date, :sale_start, :sale_end, presence: true
  validates :name, uniqueness: { scope: :start_date, message: "duplicate tournament name and start date" }

  validate :sale_end_date
  validate :sections_subset_of_event

  # @return [Array<String>] A collection of section names for this event. Mostly "Minor", "Intermediate", "Major", "Masters"
  def section_names
    sections.split(',').map {|s| s.strip}
  end

  def description(full=false)
    parts = []
    parts.push "Entry for" if full
    parts.push name
    parts.push year || years
    parts.join(" ")
  end

  def copy
    fee = self.dup
    fee.name = nil
    fee.amount = nil
    fee.becomes(Fee)
  end

  def rolloverable?
    dups = Fee::Entry.where(name: name)
    dups = dups.where(year: year + 1) if year
    dups = dups.where(years: season.next.to_s) if years
    dups.count == 0
  end

  def rollover
    fee = self.dup
    fee.advance_1_year
    fee.becomes(Fee)
  end

  def applies_to?(user)
    return false unless user.player
    return false if Item::Entry.any_duplicates(self, user.player).exists?
    true
  end

  private

  def default_attributes
    if start_date.present?
      self.sale_end = start_date.days_ago(1) if sale_end.blank?
      self.sale_start = start_date.months_ago(3) if sale_start.blank?
      if end_date.present?
        if start_date.year == end_date.year
          self.year = start_date.year
          self.years = nil
        else
          season = Season.new("#{start_date.year} #{end_date.year}")
          self.years = season.to_s unless season.error
          self.year = nil
        end
      end
    end
  end

  def sale_end_date
    if sale_end.present? && start_date.present? && sale_end > start_date
      errors.add(:sale_end, "should end on or before the start date")
    end
  end

  def sections_subset_of_event
    if event
      if event.sections.present?
        unless (section_names - event.section_names).empty?
          errors.add(:sections, "Can only include #{event.sections}")
        end
      elsif sections.present?
        errors.add(:sections, "The event has no sections listed, so you don't need to specify any for the entry fee")
      end
    elsif sections.present?
      errors.add(:sections, "This entry fee is not associated with an event, so you can't specify sections")
    end
  end
end
