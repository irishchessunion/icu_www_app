class SponsorsController < ApplicationController
  def index
    params.delete(:status) if current_user.guest? # guests don't get to search by status
    @sponsors = Sponsor.paginate(Sponsor.all, params, sponsors_path)
    flash.now[:warning] = t("no_matches") if @sponsors.count == 0
  end

  def click_on
    @sponsor = Sponsor.find(params[:id])
    @sponsor.record_click
    redirect_to @sponsor.weblink
  end
end
