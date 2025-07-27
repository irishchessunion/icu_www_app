class Admin::ItemsController < ApplicationController
  before_action :set_item, only: [:edit, :update]
  authorize_resource only: [:edit, :update]

  def index
    authorize! :index, Item
    @params = params.permit(:description, :type, :status, :payment_method, :player_id, :first_name, :last_name, :from_date, :to_date, :format, :commit)
    params[:format] = 'csv' if generating_csv?

    # A hash condition is used in ability.rb due to accessible_by not working with the nested joins
    # This is ugly but it prevents an AssocationError
    if can?(:manage, [Item::Entry, Item::Subscription, Item::Other])
      @items = Item.search(params, admin_items_path)
    else
      @items = Item::Entry.accessible_by(current_ability).search(params, admin_items_path)
    end

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

  def lifetime_form
    authorize! :manage, Player
  end

  def lifetime_create
    authorize! :manage, Player
    @params = params.permit(:item_player_id)
    begin
      Item::Subscription.new_lifetime_member(params[:item_player_id])
      redirect_to icu_life_members_path
    rescue ArgumentError => e
      redirect_to lifetime_form_admin_items_path, alert: e
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
    @item.update(item_params)
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
    generator.generate_from_items(@items, params[:description], can?(:show, Cart))
  end

  def txt_data
    generator = Admin::SwissManagerGenerator.new
    generator.generate_from_items(@items)
  end
end
