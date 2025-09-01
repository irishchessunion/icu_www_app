class Admin::LifeMembersController < ApplicationController
  before_action :authorize

  def create
    begin
      Item::Subscription.new_lifetime_member(life_member_params[:item_player_id])
      redirect_to icu_life_members_path
    rescue ArgumentError => e
      redirect_to new_admin_life_member_path, alert: e
    end
  end

  private

  def authorize
    authorize! :manage, Player
  end

  def life_member_params
    params.permit(:item_player_id)
  end
end