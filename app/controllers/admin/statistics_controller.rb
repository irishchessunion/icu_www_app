class Admin::StatisticsController < ApplicationController
  authorize_resource

  # GET /admin/statistics
  def index
    @statistics = Admin::Statistic.all
  end

  private
    # Only allow a trusted parameter "white list" through.
    def admin_statistic_params
      params.require(:admin_statistic).permit(:index)
    end
end
