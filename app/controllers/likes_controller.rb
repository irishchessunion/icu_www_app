class LikesController < ApplicationController
  # POST /likes
  def create
    identify_item_to_like
    if @like_class.like(current_user, @item)
      notice = "You like this #{@item_name}"
    else
      notice = "You were not able to like this #{@item_name}"
    end

    respond_to do |format|
      format.html { redirect_to @redirect_path, notice: notice }
      format.js { render 'create' }
    end
  end

  # DELETE /likes/1
  def destroy
    identify_item_to_like
    if @like_class.unlike(current_user, @item)
      notice = "You unliked this #{@item_name}"
    else
      notice = "You were not able to unlike this #{@item_name}"
    end

    respond_to do |format|
      format.html { redirect_to @redirect_path, notice: notice }
      format.js { render 'create' }
    end
  end

  private

  def identify_item_to_like
    if params[:news_id]
      @item = News.find(params[:news_id])
      @like_class = NewsLike
      @item_name = 'news item'
      @redirect_path = home_path
    elsif params[:article_id]
      @item = Article.find(params[:article_id])
      @like_class = ArticleLike
      @item_name = 'article'
      @redirect_path = articles_path
    else
      raise 'Can only like or unlike a news item or an article'
    end
  end
end
