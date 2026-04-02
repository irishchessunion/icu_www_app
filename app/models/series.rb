class Series < ApplicationRecord
  include Journalable
  include Pageable

  journalize %w[title], "/series/%d"

  has_many :episodes, dependent: :delete_all
  has_many :articles, through: :episodes

  validates :title, presence: true, uniqueness: true

  scope :include_articles, -> { includes(episodes: :article) }
  scope :ordered, -> { order(:title) }

  def self.search(params, path, user)
    matches = ordered.include_articles
    matches = matches.where("title LIKE ?", "%#{params[:title]}%") if params[:title].present?
    paginate(matches, params, path)
  end

  def max_number
    episodes.maximum(:number) || 0
  end
end
