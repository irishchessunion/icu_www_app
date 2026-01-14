class PagesController < ApplicationController
  before_action :load_donate_fee, except: :not_found

  def home
    @news = News.active.nonjunior.ordered.limit(8)
    @ongoing_events = Event.active.short.where(category: %w(irish women)).where('start_date <= ? AND end_date >= ?', Date.today, Date.today).ordered.limit(4)
    @upcoming_events = Event.active.short.where(category: %w(irish women)).where('start_date > ?', Date.today).ordered.limit(4)
    @reports = Article.active.tournament.ordered.limit(3)
    @results = Result.recent
  end

  def home2
    @news = News.active.nonjunior.ordered.limit(8)
    @ongoing_events = Event.active.short.where(category: %w(irish women)).where('start_date <= ? AND end_date >= ?', Date.today, Date.today).ordered.limit(4)
    @upcoming_events = Event.active.short.where(category: %w(irish women)).where('start_date > ?', Date.today).ordered.limit(4)
    @results = Result.recent
  end

  def juniors
    @news = News.active.junior.ordered.limit(8)
    @junior_events = Event.active.short.junior.where('end_date >= ?', Date.today).ordered.limit(4)
    @international_events = Event.active.short.junint.where('end_date >= ?', Date.today).ordered.limit(4)
    @junior_clubs = Club.active.junior
  end

  def beginners
    @news = News.active.beginners
    @junior_clubs = Club.active.junior
    @clubs = Club.active
  end

  def women
    @news = News.active.women.ordered
    @woman_events = Event.active.short.women.where('end_date >= ?', Date.today).ordered.limit(4)
    @international_events = Event.active.short.wint.where('end_date >= ?', Date.today).ordered.limit(4)
    @officers = Officer.active.ordered.include_players
    @officer = @officers.find { |officer| officer.role == "women" }
  end

  # this method can't be called parents as this is already a ruby method
  def for_parents
    @news = News.active.for_parents
    @junior_clubs = Club.active.junior
  end

  def primary_schools
    @news = News.active.primary
    @junior_clubs = Club.active.junior
  end

  def secondary_schools
    @news = News.active.secondary
    @junior_clubs = Club.active.junior
  end

  private

  def load_donate_fee
    @donate_fee = Fee.where(name: "Donation").first
  end
end
