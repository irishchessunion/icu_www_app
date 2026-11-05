module SessionsHelper
  private

  # @return [User]
  def current_user
    return @current_user if @current_user
    if session[:user_id]
      @current_user = User.include_player.where(id: session[:user_id]).first
      unless @current_user
        details = failure_details(message: "the session contained an invalid user ID", user_id: session[:user_id])
        Failure.log("InvalidSessionUserID", details)
        session.delete(:user_id)
      end
      # Disabling an account also signs it out.
      unless @current_user.nil? || @current_user.status_ok?
        session.delete(:user_id)
        @current_user = nil
      end
    end
    @current_user ||= User::Guest.new
  end

  # @return [Cart]
  def current_cart(option=nil)
    # If there's no memoized cart, see if there's one in the session.
    if !@current_cart && session[:cart_id]
      @current_cart = Cart.include_items_plus.where(id: session[:cart_id], status: "unpaid").first
      # Missing if the nightly cleanup deleted it, or it was paid for, while the session cookie lived on.
      session.delete(:cart_id) unless @current_cart
    end

    # If an unpaid cart exists return it immediately.
    return @current_cart if @current_cart && @current_cart.unpaid?

    # Ensure there's no paid cart hanging around.
    clear_current_cart

    # Create a new cart but only if requested.
    if option == :create
      @current_cart = Cart.create
      session[:cart_id] = @current_cart.id
    end

    # Return whatever we have left at this point (new empty cart or nil).
    @current_cart
  end

  def clear_current_cart
    @current_cart = nil
    session.delete(:cart_id)
  end

  def complete_cart(cart_id)
    clear_current_cart
    session[:completed_carts] ||= []
    session[:completed_carts].unshift cart_id
  end

  def completed_carts
    cart_ids = session[:completed_carts] || []
    cart_ids.map { |id| Cart.include_items_plus.where(id: id, status: "paid").first }
  end

  # @return [Cart]
  def last_completed_cart
    cart_ids = session[:completed_carts] || []
    return if cart_ids.empty?
    Cart.include_items_plus.where(id: cart_ids[0], status: "paid").first
  end
end
