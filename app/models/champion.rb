class Champion < ApplicationRecord
  include Expandable
  include Journalable
  include Normalizable
  include Pageable

  belongs_to :image

  journalize %w[category notes winners year image_id], "/champions/%d"

  CATEGORIES = %w[open women u19 g19 u16 g16 u14 g14 u12 g12 u10 g10 u8 g8]

  scope :ordered, -> { order(year: :desc, category: :asc) }
  scope :recent, -> (category) { where(category: category).ordered.limit(1)}

  before_validation :normalize_attributes, :correct_winners

  validates :category, inclusion: { in: CATEGORIES }, uniqueness: { scope: :year, message: "one category per year" }
  validates :winners, length: { maximum: 140 }
  validates :notes, length: { maximum: 256 }, allow_nil: true
  validates :year, numericality: { integer_only: true, greater_than_or_equal_to: Global::MIN_YEAR, less_than_or_equal_to: Date.today.year }
  validate :expansions

  def self.search(params, path)
    matches = ordered
    matches = matches.where(category: params[:category]) if CATEGORIES.include?(params[:category])
    matches = matches.where("winners LIKE ?", "%#{params[:winner]}%") if params[:winner].present?
    matches = matches.where("year LIKE ?", "%#{params[:year]}%") if params[:year].present? && params[:year].match(/\A(18|19|20)/)
    paginate(matches, params, path)
  end

  def html_notes
    notes.present? ? expand_all(notes).html_safe : ""
  end

  private

  def normalize_attributes
    notes.markoff!.trim! if notes.present?
    normalize_blanks(:notes)
  end

  def correct_winners
    if winners.present?
      winners.gsub!(/[`‘’]/, "'")
      winners.gsub!(/\s*([-.',])\s*/, '\1')
      winners.gsub!(/([\.,])/, '\1 ')
      winners.gsub!(/\b([A-Z])\s+(?!\.)/, '\1. ')
      winners.gsub!(/\b([A-Z]{2,}|[a-z]{2,})\b/) { $1.capitalize }
      winners.trim!
    end
  end

  def expansions
    if notes.present?
      begin
        expand_all(notes, true)
      rescue => e
        errors.add(:base, e.message)
      end
    end
  end
end
