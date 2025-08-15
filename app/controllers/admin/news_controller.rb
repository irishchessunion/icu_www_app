class Admin::NewsController < ApplicationController
  before_action :set_news, only: [:edit, :update, :destroy]
  authorize_resource

  def new
    @news = News.new(headline: params[:headline], summary: params[:summary])
  end

  def create
    @news = News.new(news_params)
    @news.date = Date.today
    @news.user_id = current_user.id
    set_selected_categories

    if @news.save
      @news.journal(:create, current_user, request.remote_ip)
      redirect_to @news, notice: "News was successfully created"
    else
      flash_first_error(@news, base_only: false)
      render action: "new"
    end
  end

  def update
    normalize_newlines(:news, :summary)
    set_selected_categories
    if @news.update(news_params(false))
      @news.journal(:update, current_user, request.remote_ip)
      redirect_to @news, notice: "News was successfully updated"
    else
      flash_first_error(@news, base_only: false)
      render action: "edit"
    end
  end

  def destroy
    @news.journal(:destroy, current_user, request.remote_ip)
    @news.destroy
    redirect_to news_index_path, notice: "News was successfully deleted"
  end

  private

  def set_news
    @news = News.find(params[:id])
  end

  def news_params(new_record=true)
    atrs = [:active, :headline, :summary]
    atrs.push(:date) unless new_record
    params[:news].permit(*atrs)
  end

  def set_selected_categories
    if params[:news][:selected_categories].present?
      @news.selected_categories = params[:news][:selected_categories]
      # We need to delete the selected_categories param to avoid warnings in the News update method.
      params[:news].delete(:selected_categories)
    end
  end
end
