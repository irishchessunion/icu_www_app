class Admin::OverviewController < ApplicationController
  before_action :authorize_overview

  def show
    # Latest Players uses record creation time; the chart uses the ICU joining date.
    @latest_players = Player.non_duplicates.where.not(created_at: nil).
      select(:id, :first_name, :last_name, :created_at).
      order(created_at: :desc, id: :desc).limit(8)
  end

  def new_players
    period = params.fetch(:period, "month")
    return head :bad_request unless Admin::NewPlayersChart::PERIODS.include?(period)

    render json: Admin::NewPlayersChart.new(period: period).data
  end

  private

  def authorize_overview
    authorize! :show, :admin_overview
  end
end
