class UploadsController < ApplicationController
  def index
    @uploads = Upload.search(params, uploads_path, current_user)
    flash.now[:warning] = t("no_matches") if @uploads.count == 0
    save_last_search(:uploads)
  end

  def show
    @upload = Upload.find(params[:id])
    raise CanCan::AccessDenied.new("Not authorized!", :read, Upload) unless @upload.accessible_to?(current_user)
    redirect_to @upload.url
  end
end