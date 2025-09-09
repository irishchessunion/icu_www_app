class News < ApplicationRecord
  include Expandable
  include Normalizable
  include Pageable
  include Remarkable
  include Journalable

  include CategoriesOwner

  journalize %w[active date headline summary categories], "/news/%d"

  belongs_to :user

  before_validation :normalize_attributes
  validates :headline, presence: true, on: :create, length: { maximum: 100 }
  validates :summary, presence: true, on: :create, length: { maximum: 140, too_long: 'The summary is too long. Please create an article, and link to it so: [ART:123:My Article]' }
  validates :date, date: { on_or_before: :today }
  validate :expansions

  scope :include_player, -> { includes(user: :player) }
  scope :ordered, -> { order(date: :desc, updated_at: :desc) }
  scope :linked_to_game, -> { where("headline like '%[GME:%' or summary like '%[GME:%'") }
  scope :junior, -> { juniors }
  scope :nonjunior, -> { where("categories = 0 or categories & #{bitset_for_categories([:juniors, :for_parents, :primary, :secondary, :beginners])} = 0")}
  scope :active, -> { where(active: true) }
  # The category specific scopes are automatically created by has_flags.
  scope :woman, -> { where(category: "woman") }

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

  def html
    to_html(expand_all(summary), filter_html: false)
  end

  def html2
    to_html(expand_all("#{date.strftime('%d-%m-%Y')}: #{summary}"), filter_html: false)
  end

  def expand(opt)
    %q{<a href="/news/%d">%s</a>} % [id, opt[:text] || headline]
  end

  def short_date
    "#{date.mon}-#{date.mday}"
  end

  # Just returns the Like class for this type of item
  def like_class
    NewsLike
  end

  def like_button_options
    { news_id: id }
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
    if summary.present?
      begin
        expand_all(summary, true)
      rescue => e
        errors.add(:base, e.message)
      end
    end
  end
end
