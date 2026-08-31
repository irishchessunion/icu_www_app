class Admin::EventIdsController < ApplicationController
  def index
    authorize! :index, Event
    matches = Event.order(start_date: :desc)
    matches = matches.where("name LIKE ?", "%#{params[:name]}%") if params[:name].present?
    @events = Event.paginate(matches, params, admin_event_ids_path, remote: true, per_page: 10)
  end
end
