class LikesController < ApplicationController
  # POST /likes
  def create
    if NewsLike.like(current_user, News.find(params[:news_id]))
      redirect_to home2_path, notice: 'You like this news item'
    else
      redirect_to home2_path, notice: 'You were not able to like this news item'
    end
  end

  # DELETE /likes/1
  def destroy
    if NewsLike.unlike(current_user, News.find(params[:id]))
      redirect_to home2_path, notice: 'You unliked this news item'
    else
      redirect_to home2_path, notice: 'You were not able to unlike this news item'
    end
  end
end
