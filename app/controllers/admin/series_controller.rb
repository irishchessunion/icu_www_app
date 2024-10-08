class Admin::SeriesController < ApplicationController
  before_action :set_series, only: [:edit, :update, :destroy]
  authorize_resource

  def new
    @series = Series.new
  end

  def create
    @series = Series.new(series_params)

    if @series.save
      @series.journal(:create, current_user, request.remote_ip)
      update_episodes
      redirect_to @series, notice: "Series was successfully created"
    else
      flash_first_error(@series, base_only: true)
      render action: "new"
    end
  end

  def update
    if @series.update(series_params)
      @series.journal(:update, current_user, request.remote_ip)
      update_episodes
      redirect_to @series, notice: "Series was successfully updated"
    else
      flash_first_error(@series, base_only: true)
      render action: "edit"
    end
  end

  def destroy
    @series.journal(:destroy, current_user, request.remote_ip)
    @series.destroy
    redirect_to series_index_path, notice: "Series was successfully deleted"
  end

  private

  def set_series
    @series = Series.include_articles.find(params[:id])
  end

  def series_params
    params[:series].permit(:title)
  end

  def update_episodes
    delete_episodes
    add_episodes
  end

  def delete_episodes
    article_ids = @series.articles.map(&:id)
    old_ids = article_ids - (params[:keep] || []).map(&:to_i)
    old_ids.each do |id|
      episode = @series.episodes.find_by(article: id)
      episode.destroy if episode
    end
  end

  def add_episodes
    article_ids = @series.articles.all.map(&:id)
    new_ids = id_num_pairs.reject{ |pair| article_ids.include?(pair[:id]) }
    new_ids.each do |pair|
      article = Article.find_by(id: pair[:id])
      Episode.create(series: @series, article: article, number: pair[:num]) if article
    end
  end

  def id_num_pairs
    if params[:add].is_a?(Array) && params[:num].is_a?(Array) && params[:add].size == params[:num].size
      params[:add].each_with_index.map do |id, index|
        { id: id.to_i, num: params[:num][index].to_i }
      end.reject do |pair|
        pair[:id] == 0
      end.uniq do |pair|
        pair[:id]
      end
    else
      []
    end
  end
end
