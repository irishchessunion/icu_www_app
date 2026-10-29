class Admin::OverviewController < ApplicationController
  def show
    authorize! :show, :admin_overview
  end
end
