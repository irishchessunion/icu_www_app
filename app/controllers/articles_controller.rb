class ArticlesController < ApplicationController
  def index
    authorize! :index, Article
    params[:active] = "true" unless can?(:manage, Article)
    @articles = Article.search(params, articles_path, current_user)
    flash.now[:warning] = t("no_matches") if @articles.count == 0
    save_last_search(@articles, :articles)
  end

  def show
    @article = Article.include_player.include_series.find(params[:id])
    raise CanCan::AccessDenied.new(nil, :read, Article) unless @article.accessible_to?(current_user)
    @prev_next = Util::PrevNext.new(session, Article, params[:id])
    @entries = @article.journal_search if can?(:create, Article)
  end

  def source
    authorize! :create, Article
    @article = Article.find(params[:id])
  rescue => e
    @error = e.message
  end
end
