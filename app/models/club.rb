class Club < ApplicationRecord
  include Expandable
  include Geocodable
  include Journalable
  include Normalizable
  include Pageable
  include Remarkable
  include WysiwygEditable

  journalize %w[name web meet address district city county lat long contact email phone active description notes secretary_id], "/clubs/%d"

  has_many :players
  has_many :club_meetings, dependent: :destroy
  belongs_to :secretary, class_name: "Player", optional: true
  accepts_nested_attributes_for :club_meetings, allow_destroy: true, reject_if: :all_blank

  default_scope { order(:name) }
  scope :active, -> { where(active: true) }
  scope :junior_only, -> { where(junior_only: true) }
  scope :junior, -> { where("junior_only = true or has_junior_section = true") }
  scope :with_geocodes, -> { where.not(lat: nil).where.not(long: nil) }

  before_validation :normalize_attributes

  wysiwyg_editable :notes, required: false, filter_html: true
  validate :notes_expansions

  validate :has_contact_method

  validates :name, presence: true, uniqueness: true
  validates :web, url: true, allow_nil: true
  validates :meet, :address, :district, presence: true, allow_nil: true
  validates :city, presence: true
  validates :county, inclusion: { in: Ireland.counties, message: "invalid county" }
  validates :lat,  numericality: { greater_than:  51.2, less_than: 55.6, message: "must be between 51.2 and 55.6" }, allow_nil: true
  validates :long, numericality: { greater_than: -10.6, less_than: -5.3, message: "must be between -10.6 and -5.3" }, allow_nil: true
  validates :contact, presence: true, allow_nil: true
  validates :email, email: true, allow_nil: true
  validates :phone, format: { with: /\d{3}/ }, allow_nil: true
  validates :active, inclusion: { in: [true, false] }
  validate :secretary_exists

  def province
    Ireland.province(county)
  end

  def contactable?
    phone.present? || email.present? || web.present?
  end

  def self.search(params)
    matches = all.preload(:club_meetings)

    if params[:search].present?
      term = "%#{sanitize_sql_like(params[:search].squish)}%"
      matches = matches.where("name LIKE :term OR address LIKE :term OR city LIKE :term OR county LIKE :term", term: term)
    end

    matches = matches.where(county: params[:county]) if Ireland.county?(params[:county])
    matches = matches.active unless params[:include_inactive].present?

    meetings = ClubMeeting.all
    filter_meetings = false

    if ClubMeeting::DAYS_OF_WEEK.include?(params[:day_of_week])
      meetings = meetings.where(day_of_week: params[:day_of_week])
      filter_meetings = true
    end

    if %w[juniors_only women_only].include?(params[:audience])
      meetings = meetings.where(audience: params[:audience])
      filter_meetings = true
    end

    if params[:audience] == "adults_only"
      adult_matches = matches.where(id: meetings.where(welcomes_juniors: false).select(:club_id))
      unless filter_meetings
        legacy_matches = matches.where.not(id: ClubMeeting.select(:club_id))
          .where.not(meet: [nil, ""]).where(junior_only: false, has_junior_section: false)
        adult_matches = adult_matches.or(legacy_matches)
      end
      matches = adult_matches

    elsif params[:audience] == "juniors_only"
      junior_matches = matches.where(id: meetings.select(:club_id))
      unless ClubMeeting::DAYS_OF_WEEK.include?(params[:day_of_week])
        legacy_matches = matches.where.not(id: ClubMeeting.select(:club_id)).where(junior_only: true)
        junior_matches = junior_matches.or(legacy_matches)
      end
      matches = junior_matches

    elsif filter_meetings
      matches = matches.where(id: meetings.select(:club_id))
    end

    matches

  end

  def geocodes?
    active && lat.present? && long.present?
  end

  def location
    location_parts.join(", ")
  end

  def location_parts
    address.to_s.split(",").map(&:strip).reject(&:blank?) + locality_parts
  end

  def locality_parts
    county_name = I18n.t("ireland.co.#{county}")
    parts = []
    parts << city if city.present? && ![county.to_s, county_name].any? { |name| city.casecmp?(name) }
    parts << "#{I18n.t('club.co')} #{county_name}"
    parts << eircode if eircode.present?
    parts
  end

  private

  def notes_expansions
    return unless notes.present?
    errors.add(:notes, "can't include images") if notes.include?("[IMG:")
    expand_all(notes, true)
  rescue => e
    errors.add(:notes, e.message)
  end

  def secretary_exists
    if secretary_id.present? && !Player.exists?(secretary_id)
      errors.add(:secretary_id, "player does not exist")
    end
  end

  def has_contact_method
    if active && !contactable?
    #   errors[:base] << "An active club must have at least one contact method (phone, email or web)"
      errors.add(:base, "An active club must have at least one contact method (phone, email or web)")
    end
  end

  def normalize_attributes
    normalize_blanks(:name, :web, :meet, :address, :district, :city, :lat, :long, :contact, :email, :phone)
    if web.present? && web.match(/\A[^.\/\s:]+(\.[^.\/\s:]+){1,}[^\s]+/)
      self.web = "http://#{web}"
    end
  end
end
