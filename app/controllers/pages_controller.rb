class PagesController < ApplicationController
  def home
    @news = News.search({ active: "true" }, news_index_path, per_page: 8)
    @junior_events = Event.active.junior.where('end_date >= ?', Date.today).ordered.limit(3)
    @irish_events = Event.active.where(category: %w(irish women)).where('end_date >= ?', Date.today).ordered.limit(4)
    @results = Result.recent
  end

  def home2
    @news = News.search({ active: "true" }, news_index_path, per_page: 8)
    @junior_events = Event.active.junior.where('end_date >= ?', Date.today).ordered.limit(3)
    @irish_events = Event.active.where(category: %w(irish women)).where('end_date >= ?', Date.today).ordered.limit(4)
    @results = Result.recent
  end

  def junior_home
    @news = News.search({ active: "true", category: "juniors" }, news_index_path, per_page: 8)
    @junior_events = Event.active.junior.where('end_date >= ?', Date.today).ordered.limit(4)
    @international_events = Event.active.junint.where('end_date >= ?', Date.today).ordered.limit(4)
    @junior_clubs = Club.junior
  end

  def not_found
    render file: "#{Rails.root}/public/404", formats: [:html], layout: false, status: 404
  end
end
