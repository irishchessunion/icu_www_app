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
  end

  def charge
    load_cart
    if @cart && !@cart.items.empty?
      @cart.purchase(params, current_user)
      complete_cart(@cart.id) if @cart.paid?
      redirect_to shop_path unless request.xhr?
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

  private

  def load_cart(option = nil)
    @cart = current_cart(option)
  end
end
