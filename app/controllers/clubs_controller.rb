class ClubsController < ApplicationController
  def index
    @include_inactive = can?(:manage, Club) || Club.accessible_by(current_ability, :update).exists?
    params.delete(:include_inactive) unless @include_inactive
    @clubs = Club.search(params).to_a
    if turbo_frame_request?
      render partial: "results"
    else
      @map_clubs = (@include_inactive ? Club.all : Club.active).with_geocodes
    end
  end

  def show
    @club = Club.find(params[:id])
    @entries = @club.journal_search if can?(:create, Club)
  end
end
