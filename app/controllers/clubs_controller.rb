class ClubsController < ApplicationController
  def index
    params.delete(:include_inactive) unless can?(:manage, Club)
    params.delete(:audience) unless %w[all adults_only juniors_only women_only].include?(params[:audience])
    @clubs = Club.search(params).to_a
    if turbo_frame_request?
      render partial: "results"
    else
      @map_clubs = (can?(:manage, Club) ? Club.all : Club.active).with_geocodes
    end
  end

  def show
    @club = Club.find(params[:id])
    @entries = @club.journal_search if can?(:create, Club)
  end
end
