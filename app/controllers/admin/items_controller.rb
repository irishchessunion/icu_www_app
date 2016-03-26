require 'csv'

class Admin::ItemsController < ApplicationController
  def index
    authorize! :index, Item
    @items = Item.search(params, admin_items_path)
    flash.now[:warning] = t("no_matches") if @items.count == 0

    respond_to do |format|
      format.html
      format.csv do
        send_data csv_data, filename: "#{params[:description]}.csv", type: 'text/csv'
      end
    end
  end
  
  def sales_ledger
    authorize! :sales_ledger, Item
    @ledger = SalesLedger.new
  end

  private

  def csv_data
    CSV.generate do |csv|
      csv << ["Items for #{params[:description]} generated on #{Time.now}", '', '', '', '']
      csv << %w(Description Player ICU# Fee Status)
      @items.each do |item|
        if item.player.present?
          name, id = item.player.name, item.player.id
        elsif new_player = item.new_player
          name, id = new_player.name, 'new'
        else
          name, id = nil, nil
        end
        csv << [item.description, name, id, item.cost, item.status]
      end
    end
  end
end
