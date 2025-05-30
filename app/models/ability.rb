class Ability
  include CanCan::Ability

  def initialize(user)
    if user.guest?
      can :show, Fee::Entry do |entry|
        !entry.organizer_only
      end
      return
    end

    can :view, :special_membership # Used in IcuController to hide life members and current members
    can :index, [Article, Download, Game, Image, Series, Tournament]
    can :show, [Article, Game, Series, Tournament]

    if user.admin?
      can :manage, :all
      return
    end

    if user.documenter?
      can :manage, Document
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

    if user.gameskeeper?
      can :manage, [Pgn, Game]
    end

    if user.inspector?
      can :show, Player
      can :manage, Admin::EntryListCsvGenerator
    end

    # Most people can report results
    # If you created a result, you can delete it.
    # Reporters can delete messages or ban people from reporting.
    unless user.disallow_reporting?
      can :create, Result
    end
    can :destroy, Result, reporter_id: user.id

    # Useful for tournament organizers
    if user.organiser?
      can [:index, :show], [Fee, Item]
      can :manage, Event, user_id: user.id
      can :manage, Fee::Entry do |fee|
        fee.event && fee.event.user_id == user.id
      end
    end

    if user.reporter?
      can [:destroy, :update], Result
    end

    if user.translator?
      can :manage, Translation
      can :show, JournalEntry, journalable_type: "Translation"
    end

    if user.auditor?
      can :index, [Item, Cart]
      can :show, Cart
      can :show_intent, Cart
    end

    if user.treasurer?
      can :create, CashPayment
      can :index, [Item, PaymentError, Refund]
      can :manage, [Cart, Fee, Sponsor, UserInput]
    end

    can :show, Fee::Entry do |entry|
      if entry.organizer_only && entry.event
        user.treasurer? || user.organiser? || (user.member? && user.id == entry.event.user_id)
      else
        true
      end
    end
    can :manage_preferences, User, id: user.id
    can [:manage_profile, :show], Player, id: user.player_id
    can :sales_ledger, Item
    can :download, Game
    can :index, Player
  end
end
