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
      format.txt do
        send_data txt_data, filename: "#{params[:description]}.txt", type: 'text/txt'
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
      csv << %w(Description Player ICU# Rating Fee Status Notes)
      @items.each do |item|
        if item.player.present?
          name, id, rating = item.player.name, item.player.id, item.player.latest_rating
        elsif new_player = item.new_player
          name, id, rating = new_player.name, 'new', 'unknown'
        else
          name, id, rating = nil, nil, nil
        end
        csv << [item.description, name, id, rating, item.cost, item.status, *item.notes]
      end
    end
  end

  def txt_data
    generator = Admin::SwissManagerGenerator.new
    generator.generate_from_items(@items)
  end
end
