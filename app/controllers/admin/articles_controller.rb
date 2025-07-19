class Admin::ArticlesController < ApplicationController
  before_action :set_article, only: [:edit, :update, :destroy]
  authorize_resource

  def new
    @article = Article.new(title: params[:title], text: params[:text])
  end

  def create
    @article = Article.new(article_params)
    @article.user_id = current_user.id

    if @article.save
      @article.journal(:create, current_user, request.remote_ip)
      redirect_to @article, notice: "Article was successfully created"
    else
      flash_first_error(@article, base_only: true)
      render action: "new"
    end
  end

  def update
    normalize_newlines(:article, :text)
    if @article.update(article_params)
      @article.journal(:update, current_user, request.remote_ip)
      redirect_to @article, notice: "Article was successfully updated"
    else
      flash_first_error(@article, base_only: true)
      render action: "edit"
    end
  end

  def destroy
    @article.journal(:destroy, current_user, request.remote_ip)
    @article.destroy
    redirect_to articles_path, notice: "Article was successfully deleted"
  end

  private

  def set_article
    @article = Article.find(params[:id])
  end

  def article_params
    params[:article].permit(:access, :active, :author, :category, :markdown, :text, :title, :year)
  end
end
