module RefundsHelper
  def refund_officer_menu(selected)
    # Get IDs for all users who have done at least one refund
    user_ids = Refund.pluck("DISTINCT user_id")

    # Get all the users' names from the IDs
    officers = User.unscoped.include_player.where(id: user_ids).map { |user| [user.player.name, user.id] }
    officers.sort!

    # Add 'Any Officer' option
    officers.unshift ["Any Officer", ""]
    
    options_for_select(officers, selected)
  end
end
