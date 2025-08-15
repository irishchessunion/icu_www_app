class Article < ApplicationRecord
  include Accessible
  include Expandable
  include Journalable
  include Normalizable
  include Pageable
  include Remarkable


  include CategoriesOwner

  journalize %w[access active author categories text title year], "/article/%d"


  belongs_to :user
  has_many :episodes, dependent: :destroy
  has_many :series, through: :episodes

  before_validation :normalize_attributes

  validates :text, presence: true
  validates :title, presence: true, on: :create, length: { maximum: 150 }
  validates :year, numericality: { integer_only: true, greater_than_or_equal_to: Global::MIN_YEAR }
  validate :expansions

  scope :include_player, -> { includes(user: :player) }
  scope :include_series, -> { includes(episodes: :series) }
  scope :ordered, -> { order(year: :desc, created_at: :desc) }
  scope :linked_to_game, -> { where("text like '%[GME:%' or title like '%[GME:%'") }
  # The category specific scopes are automatically created by has_flags.

  def self.search(params, path, user, opt={})
    matches = ordered.include_player
    matches = matches.where("author LIKE ?", "%#{params[:author]}%") if params[:author].present?
    matches = matches.where("title LIKE ?", "%#{params[:title]}%") if params[:title].present?
    matches = matches.where("text LIKE ?", "%#{params[:text]}%") if params[:text].present?
    if params[:year].present?
      if params[:year].match(/([12]\d{3})\D+([12]\d{3})/)
        matches = matches.where("year >= ?", $1.to_i)
        matches = matches.where("year <= ?", $2.to_i)
      elsif params[:year].match(/([12]\d{3})/)
        matches = matches.where(year: $1.to_i)
      else
        matches = matches.none
      end
    end
    if params[:player_id].to_i > 0
      matches = matches.joins(user: :player)
      matches = matches.where("players.id = ?", params[:player_id].to_i)
    end
    matches = accessibility_matches(user, params[:access], matches)
    matches = matches.where(active: true) if params[:active] == "true"
    matches = matches.where(active: false) if params[:active] == "false"
    matches = matches.where(sql_condition_for_flag(params[:category].to_sym, "categories")) if CategoriesOwner::CATEGORIES.include?(params[:category])
    paginate(matches, params, path, opt)
  end

  def html
    expanded = expand_all(text)
    markdown ? to_html(expanded, filter_html: false) : expanded.html_safe
  end

  def expand(opt)
    %q{<a href="/articles/%d">%s</a>} % [id, opt[:title] || title]
  end

  # Just returns the Like class for this type of item
  def like_class
    ArticleLike
  end

  def like_button_options
    { article_id: id }
  end

  # @return [Array<Numeric, String>] A collection of ids of games that are linked in the title or the text of the article.
  def game_ids
    re = /\[GME:(\d+)/
    [text.scan(re), title.scan(re)].flatten
  end

  private

  def normalize_attributes
    normalize_blanks(:author)
    normalize_newlines(:text)
  end

  def expansions
    if text.present?
      begin
        expand_all(text, true)
      rescue => e
        errors.add(:base, e.message)
      end
    end
  end
end
