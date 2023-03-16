class Admin::ItemsController < ApplicationController
  before_action :set_item, only: [:edit, :update]
  authorize_resource only: [:edit, :update]

  def index
    authorize! :index, Item
    @params = params.permit(:description, :type, :status, :payment_method, :player_id, :first_name, :last_name, :from_date, :to_date, :format)
    params[:format] = 'csv' if generating_csv?
    @items = Item.search(params, admin_items_path)
    flash.now[:warning] = t("no_matches") if @items.count == 0


    respond_to do |format|
      format.html do
        if generating_csv?
          send_data csv_data, filename: "items.csv", type: 'text/csv'
        else
          render :index
        end
      end
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

  def edit
    @fee = @item.fee
    @player_name = @item.player.name(id: true) if @item.player
  end

  def update
    @item.update_attributes(item_params)
    redirect_to event_path(@item.fee.event_id) if @item.fee.event_id
  end

  private

  def set_item
    @item = Item.find(params[:id])
  end

  private

  def generating_csv?
    params[:commit] == "Generate CSV"
  end

  def item_params
    params.require(:item).permit(:section)
  end

  def csv_data
    generator = Admin::EntryListCsvGenerator.new
    generator.generate_from_items(@items, params[:description])
  end

  def txt_data
    generator = Admin::SwissManagerGenerator.new
    generator.generate_from_items(@items)
  end
end
