class News < ApplicationRecord
  include Expandable
  include Normalizable
  include Pageable
  include Remarkable
  include Journalable
  include WysiwygEditable

  include CategoriesOwner

  journalize %w[active date headline summary categories image_id], "/news/%d"

  belongs_to :user
  # Shown beside the news item in lists, rather than in the summary
  belongs_to :image, optional: true

  before_validation :normalize_attributes

  wysiwyg_editable :summary
  validates :headline, presence: true, on: :create, length: { maximum: 100 }
  validates :date, date: { on_or_before: :today }
  validate :expansions

  scope :include_player, -> { includes(user: :player) }
  scope :include_image, -> { includes(:image) }
  scope :ordered, -> { order(date: :desc, updated_at: :desc) }
  scope :linked_to_game, -> { where("headline like '%[GME:%' or summary like '%[GME:%'") }
  scope :junior, -> { juniors }
  scope :nonjunior, -> { where("categories = 0 or categories & #{bitset_for_categories([:juniors, :for_parents, :primary, :secondary, :beginners])} = 0")}
  scope :active, -> { where(active: true) }
  # The category specific scopes are automatically created by has_flags.

  def self.search(params, path, opt={})
    matches = ordered.include_player
    matches = matches.where("headline LIKE ?", "%#{params[:headline]}%") if params[:headline].present?
    matches = matches.where("summary LIKE ?", "%#{params[:summary]}%") if params[:summary].present?
    matches = matches.where("date LIKE ?", "%#{params[:date]}%") if params[:date].present?
    if params[:player_id].to_i > 0
      matches = matches.joins(user: :player)
      matches = matches.where("players.id = ?", params[:player_id].to_i)
    end
    matches = matches.where(active: true) if params[:active] == "true"
    matches = matches.where(active: false) if params[:active] == "false"
    matches = matches.where(sql_condition_for_flag(params[:category].to_sym, "categories")) if CategoriesOwner::CATEGORIES.include?(params[:category])
    paginate(matches, params, path, opt)
  end

  def html2
    render_wysiwyg_content(expand_all("#{date.strftime('%d-%m-%Y')}: #{summary}"))
  end

  def expand(opt)
    %q{<a href="/news/%d">%s</a>} % [id, opt[:text] || headline]
  end

  def short_date
    "#{date.mon}-#{date.mday}"
  end

  # @return [Array<Numeric, String>] A collection of ids of games that are linked in the title or the text of the article.
  def game_ids
    re = /\[GME:(\d+)/
    [headline.scan(re), summary.scan(re)].flatten
  end

  private

  def normalize_attributes
    normalize_newlines(:summary)
  end

  def expansions
    # The image goes in image_id now. Older items with images in their text can still be edited.
    if summary.to_s.scan("[IMG:").size > summary_was.to_s.scan("[IMG:").size
      errors.add(:summary, "can't include new images, use the Image field instead")
    end
    if summary.present?
      begin
        expand_all(summary, true)
      rescue => e
        errors.add(:base, e.message)
      end
    end
  end
end
