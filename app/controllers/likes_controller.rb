class LikesController < ApplicationController
  # POST /likes
  def create
    @news = News.find(params[:news_id])
    if NewsLike.like(current_user, @news)
      notice = 'You like this news item'
    else
      notice = 'You were not able to like this news item'
    end

    respond_to do |format|
      format.html { redirect_to home2_path, notice: notice }
      format.js { render 'create' }
    end
  end

  # DELETE /likes/1
  def destroy
    @news = News.find(params[:id])
    if NewsLike.unlike(current_user, @news)
      notice = 'You unliked this news item'
    else
      notice = 'You were not able to unlike this news item'
    end

    respond_to do |format|
      format.html { redirect_to home2_path, notice: notice }
      format.js { render 'create' }
    end
  end
end
