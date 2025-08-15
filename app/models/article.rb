class Article < ApplicationRecord
  include Accessible
  include Expandable
  include Journalable
  include Normalizable
  include Pageable
  include Remarkable

  include FlagShihTzu

  CATEGORIES = %w[bulletin tournament biography obituary coaching juniors beginners general for_parents primary secondary women]
  # Used to convert from string to symbol, without creating extra symbols from user input
  CATEGORY_HASH = Hash[CATEGORIES.map(&:to_s).zip(0...CATEGORIES.size)]

  has_flags 1 => :bulletin,
            2 => :tournament,
            3 => :biography,
            4 => :obituary,
            5 => :coaching,
            6 => :juniors,
            7 => :beginners,
            8 => :general,
            9 => :for_parents,
            10 => :primary,
            11 => :secondary,
            12 => :women,
            :column => 'categories',
            :flag_query_mode => :bit_operator

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
    matches = matches.where(sql_condition_for_flag(params[:category].to_sym, "categories")) if CATEGORIES.include?(params[:category])
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

  # @param categories An array of strings containing potentially correct Article categories
  # @return An array of legitimate symbols
  def self.valid_categories(categories)
    valid = []
    categories.each do |category|
      index = Article::CATEGORY_HASH[category]
      if index
        valid << CATEGORIES[index]
      end
    end
    valid
  end

  # The FlagShihTzu class adds a method selected_categories= that only handles arrays of symbols.
  alias assign_selected_categories selected_categories=

  # Sets the categories bitset by convertign the array of strings to the appropriate set of bits.
  # Accepts an array of strings which should all be the string equivalent of the legal categories.
  # Any invalid strings will be ignored.
  def selected_categories=(categories)
    assign_selected_categories(Article.valid_categories(categories))
  end

  # A temporary helper method before we remove category altogether
  def category
    selected_categories.first || :any
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
