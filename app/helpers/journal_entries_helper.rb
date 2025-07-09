module JournalEntriesHelper
  def journal_entry_type_menu(selected)
    types = JournalEntry.unscoped
                     .order(:journalable_type)
                     .distinct
                     .pluck(:journalable_type)
                     .map { |t| [t, t] }
    types.unshift(["Any type", ""])
    options_for_select(types, selected)
  end

  def journal_entry_action_menu(selected)
    actions = JournalEntry::ACTIONS.map{|a| [a.capitalize, a]}
    actions.unshift(["Any action", ""])
    options_for_select(actions, selected)
  end
end