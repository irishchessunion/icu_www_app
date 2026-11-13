class Admin::EventsController < ApplicationController
  before_action :set_event, only: [:show, :entries_chart, :edit, :update, :destroy]
  authorize_resource except: [:entries_chart]

  def index
    @events = Event.admin_search(params, admin_events_path, current_user)
  end

  def show
    @entries = @event.journal_search if can?(:create, Event)
    @latest_entries = Item::Entry.paid.joins(:fee).left_joins(:cart).
      where(fees: { event_id: @event.id }).preload(:player, :cart).
      order("carts.payment_completed" => :desc, created_at: :desc, id: :desc).limit(8)
  end

  def entries_chart
    unless @event.has_full_access?(current_user) || current_user.admin? || current_user.treasurer?
      raise CanCan::AccessDenied
    end

    period = params.fetch(:period, "day")
    return head :bad_request unless Admin::EventEntriesChart::PERIODS.include?(period)

    render json: Admin::EventEntriesChart.new(@event, period: period).data
  end

  def new
    @event = Event.new
  end

  def create
    @event = Event.new(event_params)
    @event.user_id = current_user.id
    @event.markdown = false

    if @event.save
      @event.journal(:create, current_user, request.remote_ip)
      redirect_to @event, notice: "Event was successfully created"
    else
      flash_first_error(@event, base_only: true)
      render action: "new"
    end
  end

  def update
    @event.markdown = false
    if @event.update(event_params)
      @event.journal(:update, current_user, request.remote_ip)
      redirect_to admin_event_path(@event), notice: "Event was successfully updated"
    else
      flash_first_error(@event, base_only: true)
      render action: "edit"
    end
  end

  def destroy
    @event.journal(:destroy, current_user, request.remote_ip)
    @event.destroy
    redirect_to events_path, notice: "Event was successfully deleted"
  end

  private

  def set_event
    @event = Event.find(params[:id])
  end

  def event_params
    params[:event].permit(:flyer, :name, :category, :is_fide_rated, :location, :start_date, :end_date, :contact, :phone, :email,
                          :url, :pairings_url, :live_games_url, :live_games_url2, :streaming_url, :results_url, :report_url,
                          :lat, :long, :prize_fund, :active, :note, :sections, :subscription_required, :user_id,
                          :tournament_type, :time_control_details, :icu_rated, :max_participants, time_controls: [])
  end
end
