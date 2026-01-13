class PaymentsController < ApplicationController
  def shop
    @fees = Fee.for_sale
    @completed_carts = completed_carts
    @current_season = Season.new
    @next_season = @current_season.next if Date.today.month == 8
  end

  def cart
    load_cart(:create)
    redirect_to shop_path unless @cart

    if @cart.has_expired_items?
      @cart.refresh_items
    end
  end

  def card
    load_cart
    if @cart.nil? || @cart.items.empty?
      redirect_to shop_path
      return
    end
    if @cart.total_cost == 0
      render "zero_cost_card"
    end

    if @cart.has_expired_items?
      # Only should occur if the user gets to /card without going through /cart
      flash[:warning] = t("shop.payment.expired_items")
      redirect_to cart_path
    end

    @intent = @cart.create_intent if @cart.total_cost > 0
  end

  def charge
    load_cart
    if @cart && !@cart.items.empty?
      @cart.purchase(params, current_user)
      complete_cart(@cart.id) if @cart.paid?
      redirect_to confirm_path
    else
      if request.xhr?
        render nothing: true
      else
        redirect_to shop_path
      end
    end
  end

  def confirm
    @cart = last_completed_cart
    redirect_to shop_path unless @cart
  end

  def completed
    @completed_carts = completed_carts
  end

  def new_payment_error
    load_cart
    if @cart.nil? || @cart.items.empty?
      redirect_to shop_path
      return
    end
    @cart.add_payment_error(params[:error], params[:name], params[:email])
    
    if request.xhr?
      render json: nil, status: :ok
    else
      redirect_to shop_path
    end
  end

  private

  def load_cart(option = nil)
    @cart = current_cart(option)
  end
end
