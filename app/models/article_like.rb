class ArticleLike < ActiveRecord::Base
  belongs_to :user
  belongs_to :article

  validates :user, :article, presence: true
  validates_uniqueness_of :article_id, scope: :user_id

  # @param [User] user
  # @param [Article] article
  # @returns [Boolean] true if the user liked the article
  def self.like(user, article)
    transaction do
      al = ArticleLike.create(user: user, article: article)
      article.update_column(:nlikes, (article.nlikes || 0) + 1)
      al.persisted?
    end
  end

  # @param [User] user
  # @param [Article] article
  # @returns [Boolean] true if the user unliked the article
  def self.unlike(user, article)
    transaction do
      al = ArticleLike.where(user: user, article: article).first
      unless al
        return false
      end
      al.destroy
      nlikes = article.nlikes || 1
      nlikes -= 1
      nlikes = 0 if nlikes < 0
      article.update_column(:nlikes, nlikes)
      true
    end
  end
end
