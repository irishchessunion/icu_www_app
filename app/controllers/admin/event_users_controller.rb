class Admin::EventUsersController < ApplicationController
  before_action :set_event
  before_action :set_event_user, only: [:destroy]
  before_action :authorize_creator_or_admin, only: [:create, :destroy]

  def create
    @event_user = @event.event_users.new(event_user_params)

    unless @event_user.user&.organiser?
      flash.now[:alert] = I18n.t("event.admin.user_must_be_organiser")
      render "admin/events/show"
      return
    end

    if @event_user.save
      flash.now[:notice] = I18n.t("event.admin.user_added")
      render "admin/events/show"
    else
      flash.now[:alert] = @event_user.errors.full_messages.join(", ")
      render "admin/events/show"
    end
  end

  def destroy
    if @event_user.user_id == @event.user_id
      flash.now[:alert] = I18n.t("event.admin.cannot_remove_creator")
      render "admin/events/show"
      return
    end

    if @event_user.user_id == current_user.id
      flash.now[:alert] = I18n.t("event.admin.cannot_remove_self")
      render "admin/events/show"
      return
    end

    @event_user.destroy
    flash.now[:notice] = I18n.t("event.admin.user_removed")
    render "admin/events/show"
  end

  private

  def set_event
    @event = Event.find(params[:event_id])
    authorize! :read, @event
  end

  def set_event_user
    @event_user = @event.event_users.find(params[:id])
  end

  def authorize_creator_or_admin
    unless current_user.admin? || @event.creator?(current_user)
      flash.now[:alert] = I18n.t("event.admin.only_creator_or_admin")
      render "admin/events/show"
    end
  end

  def event_user_params
    params.require(:event_user).permit(:user_id, :role)
  end
end
