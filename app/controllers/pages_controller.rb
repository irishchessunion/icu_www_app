class PagesController < ApplicationController
  def home
    @news = News.search({ active: "true" }, news_index_path, per_page: 7)
    @junior_events = Event.active.where(category: 'junior').where('end_date >= ?', Date.today).limit(3)
    @irish_events = Event.active.where(category: 'irish').where('end_date >= ?', Date.today).limit(3)
  end

  def home2
    @news = News.search({ active: "true" }, news_index_path, per_page: 7)
    @junior_events = Event.active.where(category: 'junior').where('end_date >= ?', Date.today).limit(3)
    @irish_events = Event.active.where(category: 'irish').where('end_date >= ?', Date.today).limit(3)
  end

  def not_found
    render file: "#{Rails.root}/public/404", formats: [:html], layout: false, status: 404
  end
end
