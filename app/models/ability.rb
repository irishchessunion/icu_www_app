class Ability
  include CanCan::Ability

  def initialize(user)
    return if user.guest?

    if user.roles.present?
      if user.admin?
        can :manage, :all
        return
      end

      if user.tester?
        can :manage, Admin::Statistic
      end

      if user.editor?
        can :create, [Article, Event, Image, News]
        can [:create, :show], Download
        can [:create, :index, :show], Pgn
        can [:destroy, :update], [Article, Event, Image, News, Pgn, Download], user_id: user.id
        can [:destroy, :update], Game, pgn: { user_id: user.id }
        can :manage, [Champion, Club, Series, Tournament]
      end

      if user.calendar?
        can [:create, :update], Event
        can :destroy, Event, user_id: user.id
      end

      if user.membership?
        can :create, CashPayment
        can :manage, Player
      end

      if user.inspector?
        can :show, Player
      end

      # Most people can report results
      # If you created a result, you can delete it.
      # Reporters can delete messages or ban people from reporting.
      unless user.disallow_reporting?
        can :create, Result
      end
      can :destroy, Result, reporter_id: user.id

      if user.reporter?
        can [:destroy, :update], Result
      end

      if user.translator?
        can :manage, Translation
        can :show, JournalEntry, journalable_type: "Translation"
      end

      if user.treasurer?
        can :create, CashPayment
        can :index, [Item, PaymentError, Refund]
        can :manage, [Cart, Fee, UserInput]
      end
    end

    can :manage_preferences, User, id: user.id
    can [:manage_profile, :show], Player, id: user.player_id
    can :sales_ledger, Item
    can :download, Game
  end
end
