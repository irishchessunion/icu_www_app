class ItemsController < ApplicationController
  def new
    unless @fee
      @fee = fee_for_sale(params[:fee_id])
      if @fee
        @item = Item.new(fee: @fee, type: @fee.subtype(:item)).becomes(Item)
        @new_player, @player_name = new_player(@fee)
      else
        redirect_to shop_path
      end
    end
  end

  def create
    @item = Item.new(item_params)
    @fee = fee_for_sale(@item.fee_id)
    unless @fee
      redirect_to shop_path
      return
    end
    cart = current_cart(:create)
    @item.cart = cart
    original_notes = @item.notes.dup

    if save_with_overseas_subscription(cart)
      redirect_to cart_path
    else
      flash_first_error(@item)
      @new_player, @player_name = new_player(@fee, @item)
      @item = @item.becomes(Item)
      @item.notes = original_notes
      render "new"
    end
  end

  def destroy
    item = current_cart.items.find do |item|
      item.id == params[:id].to_i && item.unpaid?
    end
    item.destroy
    # An entry that relied on this subscription can't be paid for without it
    if item.is_a?(Item::Subscription)
      current_cart.items.each { |other| other.destroy if other.is_a?(Item::Entry) && other.missing_subscription? }
    end
    redirect_to cart_path
  rescue
    redirect_to shop_path
  end

  private

  # Saves the item, along with the overseas subscription an entry for a player from outside Ireland needs.
  def save_with_overseas_subscription(cart)
    saved = false
    Item.transaction do
      subscription = @item.overseas_subscription if @item.is_a?(Item::Entry)
      if subscription && !subscription.save
        subscription.errors.full_messages.each { |message| @item.errors.add(:base, message) }
        raise ActiveRecord::Rollback
      end
      saved = !cart.duplicates?(@item, add_error: true) && @item.save
      raise ActiveRecord::Rollback unless saved
    end
    saved
  end

  def item_params
    params.required(:item).permit(:type, :fee_id, :player_id, :player_data, :section, notes: [])
  end

  # Only fees which are on sale can be added to a cart, and organiser only fees just by those allowed to see them.
  def fee_for_sale(id)
    fee = Fee.on_sale.find_by(id: id)
    fee if fee && (!fee.organizer_only || can?(:show, fee))
  end

  def new_player(fee, item=nil)
    new_player = NewPlayer.new if fee.new_player_allowed?
    player_name = ""
    if item
      if item.player_id && (player = Player.find_by(id: item.player_id))
        player_name = player.name(id: true)
      elsif item.player_data && (player = NewPlayer.from_json(item.player_data)) && player.first_name && player.last_name
        new_player = player if fee.new_player_allowed?
        player_name = player.name
      end
    end
    [new_player, player_name]
  end
end
