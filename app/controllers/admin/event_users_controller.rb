class Admin::EventUsersController < ApplicationController
  before_action :set_event
  before_action :set_event_user, only: [:destroy]
  before_action :authorize_owner_or_admin, only: [:create, :destroy]

  def create
    @event_user = @event.event_users.new(event_user_params)

    unless @event_user.user&.organiser?
      redirect_to admin_event_path(@event), alert: I18n.t("event.admin.user_must_be_organiser")
      return
    end

    if @event_user.save
      redirect_to admin_event_path(@event), notice: I18n.t("event.admin.user_added")
    else
      redirect_to admin_event_path(@event), alert: @event_user.errors.full_messages.join(", ")
    end
  end

  def destroy
    if @event_user.user_id == @event.user_id
      redirect_to admin_event_path(@event), alert: I18n.t("event.admin.cannot_remove_owner")
      return
    end

    if @event_user.user_id == current_user.id
      redirect_to admin_event_path(@event), alert: I18n.t("event.admin.cannot_remove_self")
      return
    end

    @event_user.destroy
    redirect_to admin_event_path(@event), notice: I18n.t("event.admin.user_removed")
  end

  private

  def set_event
    @event = Event.find(params[:event_id])
    authorize! :read, @event
  end

  def set_event_user
    @event_user = @event.event_users.find(params[:id])
  end

  def authorize_owner_or_admin
    unless current_user.admin? || @event.owner?(current_user)
      redirect_to admin_event_path(@event), alert: I18n.t("event.admin.only_owner_or_admin")
    end
  end

  def event_user_params
    params.require(:event_user).permit(:user_id, :role)
  end
end
