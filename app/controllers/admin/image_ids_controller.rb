class Admin::ImageIdsController < ApplicationController
  def index
    authorize! :index, Image
    matches = Image.include_player.order(year: :desc, id: :desc)
    matches = matches.where("caption LIKE ?", "%#{params[:caption]}%") if params[:caption].present?
    @images = Image.paginate(matches, params, admin_image_ids_path, remote: true, per_page: 10)
  end
end
