class NewsLike < ActiveRecord::Base
  belongs_to :user
  belongs_to :news

  validates :user, :news, presence: true
  validates_uniqueness_of :news_id, scope: :user_id

  # @param [User] user
  # @param [News] news
  # @returns [Boolean] true if the user now likes the news item
  def self.like(user, news)
    if user.guest?
      raise CanCan::AccessDenied.new('Must login to like a news item', :create, NewsLike)
    elsif news.nil?
      raise CanCan::AccessDenied.new('No such news item', :create, NewsLike)
    elsif !news.active?
      raise CanCan::AccessDenied.new("Can't like an inactive news item", :create, NewsLike)
    end

    transaction do
      if likes?(user, news)
        return true
      end
      nl = create(user: user, news: news)
      update_nlikes(news)
      nl.persisted?
    end
  end

  # @param [User] user
  # @param [News] news
  # @returns [Boolean] true if the user no longer likes the news item
  def self.unlike(user, news)
    if user.guest?
      raise CanCan::AccessDenied.new('Must login to unlike a news item', :create, NewsLike)
    elsif news.nil?
      raise CanCan::AccessDenied.new('No such news item', :create, NewsLike)
    elsif !news.active?
      raise CanCan::AccessDenied.new("Can't unlike an inactive news item", :create, NewsLike)
    end

    transaction do
      nl = where(user: user, news: news).first
      unless nl
        return true
      end
      nl.destroy
      update_nlikes(news)
      true
    end
  end

  # @param user [User]
  # @param news [News]
  # @return [Boolean] true if the user already likes the news item
  def self.likes?(user, news)
    where(user: user, news: news).exists?
  end

  def self.update_nlikes(news)
    news.update_column(:nlikes, where(news: news).count)
  end
end
