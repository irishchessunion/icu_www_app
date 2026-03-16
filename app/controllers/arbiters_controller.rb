class ArbitersController < ApplicationController
  before_action :set_arbiter, only: [:show, :edit, :update, :destroy]
  authorize_resource

  def index
    @arbiters = can?(:manage, Arbiter) ? Arbiter.ordered.include_players : Arbiter.active.ordered.include_players
  end

  def show
    @entries = @arbiter.journal_search if can?(:manage, Arbiter)
  end

  def new
    @arbiter = Arbiter.new
  end

  def create
    @arbiter = Arbiter.new(arbiter_params)
    if @arbiter.save
      @arbiter.journal(:create, current_user, request.remote_ip)
      redirect_to @arbiter, notice: "Arbiter was successfully created"
    else
      render action: "new"
    end
  end

  def update
    if @arbiter.update(arbiter_params)
      @arbiter.journal(:update, current_user, request.remote_ip)
      redirect_to @arbiter, notice: "Arbiter was successfully updated"
    else
      flash_first_error(@arbiter, base_only: true)
      render action: "edit"
    end
  end

  def destroy
    @arbiter.journal(:destroy, current_user, request.remote_ip)
    @arbiter.destroy
    redirect_to arbiters_path, notice: "Arbiter was successfully deleted"
  end

  private

  def set_arbiter
    @arbiter = Arbiter.include_players.find(params[:id])
  end

  def arbiter_params
    if can?(:manage, Arbiter)
      params.require(:arbiter).permit(:player_id, :email, :phone, :location, :level, :date_of_qualification, :active)
    else
      params.require(:arbiter).permit(:email, :phone, :location)
    end
  end
end
