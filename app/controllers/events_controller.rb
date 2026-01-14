require 'uri'
require 'cgi'

class EventsController < ApplicationController
  def index
    @events = Event.search(params, events_path)
    @map_events = Event.with_geocodes.search(params, events_path)
    # Map coordinates of default area bounds [Lat, Lng]
    @center = [53.45, -7.95]
    @zoom = 6.4
    flash.now[:warning] = t("no_matches") if @events.count == 0
    save_last_search(@events, :events)
  end

  def show
    @event = Event.find(params[:id])
    @prev_next = Util::PrevNext.new(session, Event, params[:id])
    @entries = @event.journal_search if can?(:create, Event)
    @extras = {}
    if can?(:update, @event)
      sample_text = "[EVT:#{params[:id]}] ..."
      @extras[t("event.create_entry_fee")] = new_admin_fee_path(type: "Fee::Entry", event_id: @event.id)
      @extras["Create Article"] = new_admin_article_path(title: @event.name, text: sample_text)
      @extras["Create News Item"] = new_admin_news_path(headline: @event.name, summary: sample_text)
    end
    if @event.streaming_url.present?
      uri = URI.parse(@event.streaming_url) rescue nil

      if uri
        case uri.host
        when /youtube\.com/
          params = CGI.parse(uri.query.to_s)
          @youtube_video_id = params['v']&.first
        when /youtu\.be/
          @youtube_video_id = uri.path.split('/')[1]
        when /twitch\.tv/
          params = CGI.parse(uri.query.to_s)
          @twitch_channel_id = uri.path.split('/')[1]
        end
      end

    end
  end

  def history
    @past_events = Event.paginate(Event.past.active, params, history_events_path)
    flash.now[:warning] = t("no_matches") if @past_events.matches.empty?
  end

  def swiss_manager
    event = Event.find(params[:id])
    authorize! :update, event

    items = Item::Entry.joins(:cart, :fee_entry => :event).paid.where(section: params[:section]).where("fees.event_id = ?", event.id)
    generator = Admin::SwissManagerGenerator.new

    send_data generator.generate_from_items(items), filename: download_filename(event, params[:section], 'txt'), type: 'text/txt'
  end

  def csv_list
    event = Event.find(params[:id])
    authorize! :update, event
    
    items = Item::Entry.joins(:fee_entry => :event).paid.where(section: params[:section]).where("fees.event_id = ?", event.id)
    generator = Admin::EntryListCsvGenerator.new

    send_data generator.generate_from_items(items, event.name, can?(:show, Cart)), filename: download_filename(event, params[:section], 'csv'), type: 'text/csv'
  end

  def excel_list
    event = Event.find(params[:id])
    authorize! :update, event

    items = Item::Entry.joins(:fee_entry => :event).paid.where(section: params[:section]).where("fees.event_id = ?", event.id)
    generator = Admin::EntryListExcelGenerator.new

    send_data generator.generate_from_items(items), filename: download_filename(event, params[:section], 'xlsx'), type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
  end

  private

  def download_filename(event, section, extension)
    if section.present?
      "#{event.name} #{section}.#{extension}"
    else
      "#{event.name}.#{extension}"
    end
  end
end
