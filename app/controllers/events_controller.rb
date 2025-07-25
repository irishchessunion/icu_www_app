class EventsController < ApplicationController
  def index
    @events = Event.search(params, events_path)
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
  end

  def swiss_manager
    event = Event.find(params[:id])
    items = Item::Entry.joins(:cart, :fee_entry => :event).paid.where(section: params[:section]).where("fees.event_id = ?", event.id)
    generator = Admin::SwissManagerGenerator.new

    send_data generator.generate_from_items(items), filename: download_filename(event, params[:section], 'txt'), type: 'text/txt'
  end

  def csv_list
    event = Event.find(params[:id])
    items = Item::Entry.joins(:fee_entry => :event).paid.where(section: params[:section]).where("fees.event_id = ?", event.id)
    generator = Admin::EntryListCsvGenerator.new

    send_data generator.generate_from_items(items, event.name, can?(:show, Cart)), filename: download_filename(event, params[:section], 'csv'), type: 'text/csv'
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
