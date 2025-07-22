class Admin::CartsController < ApplicationController
  authorize_resource

  def index
    @carts = Cart.search(params, admin_carts_path)
    flash.now[:warning] = t("no_matches") if @carts.count == 0
    save_last_search(@carts, :carts)
  end

  def show
    @cart = Cart.include_items_plus.include_errors.include_refunds.find(params[:id])
    @prev_next = Util::PrevNext.new(session, Cart, params[:id], admin: true)
  end

  def show_intent
    @cart = Cart.find(params[:id])
    if @cart.payment_ref.start_with?("pi_")
      @intent = Stripe::PaymentIntent.retrieve(@cart.payment_ref)
    elsif @cart.payment_ref.start_with?("ch_")
      @intent = Stripe::Charge.retrieve(@cart.payment_ref)
    end
    @json = JSON.pretty_generate(@intent.as_json)
  rescue => e
    @error = e.message
  end

  def edit
    @cart = Cart.include_items_plus.find(params[:id])
    redirect_to [:admin, @cart] if @cart.all_items_refunded?
  end

  def update
    @cart = Cart.include_items_plus.find(params[:id])
    item_ids = params.keys.map{ |k| k.match(/\Aitem_([1-9]\d*)\z/) ? $1.to_i : nil }.compact
    if item_ids.size == 0
      flash.now[:warning] = "Please either click #{I18n.t('cancel')} or select one or more items and then click #{@cart.refund_type}"
      render "edit"
    else
      refund = @cart.refund(item_ids, current_user)
      if refund.error.present?
        flash.now[:alert] = refund.error
        render "edit"
      else
        flash[:notice] = "#{@cart.refund_type} was successful"
        redirect_to [:admin, @cart]
      end
    end
  end
end
