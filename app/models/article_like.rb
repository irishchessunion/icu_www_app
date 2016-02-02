class ArticleLike < ActiveRecord::Base
  belongs_to :article
  belongs_to :user

  validates :user, :article, presence: true
  validates_uniqueness_of :article_id, scope: :user_id

  # @param [User] user
  # @param [Article] article
  # @returns [Boolean] true if the user now likes the news item
  def self.like(user, article)
    if user.guest?
      raise CanCan::AccessDenied.new('Must login to like an article', :create, ArticleLike)
    elsif article.nil?
      raise CanCan::AccessDenied.new('No such article', :create, ArticleLike)
    elsif !article.active?
      raise CanCan::AccessDenied.new("Can't like an inactive article", :create, ArticleLike)
    end

    transaction do
      if likes?(user, article)
        return true
      end
      like = create(user: user, article: article)
      update_nlikes(article)
      like.persisted?
    end
  end

  # @param [User] user
  # @param [Article] article
  # @returns [Boolean] true if the user no longer likes the article
  def self.unlike(user, article)
    if user.guest?
      raise CanCan::AccessDenied.new('Must login to unlike an article', :create, ArticleLike)
    elsif article.nil?
      raise CanCan::AccessDenied.new('No such article', :create, ArticleLike)
    elsif !article.active?
      raise CanCan::AccessDenied.new("Can't unlike an inactive article", :create, ArticleLike)
    end

    transaction do
      like = where(user: user, article: article).first
      unless like
        return true
      end
      like.destroy
      update_nlikes(article)
      true
    end
  end

  # @param user [User]
  # @param article [Article]
  # @return [Boolean] true if the user already likes the article
  def self.likes?(user, article)
    where(user: user, article: article).exists?
  end

  # @param article [Article]
  def self.update_nlikes(article)
    article.update_column(:nlikes, where(article: article).count)
  end
end
