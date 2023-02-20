class AlterJournalEntries < ActiveRecord::Migration[7.0]
  change_table :journal_entries do |t|
    t.change :by, :string
  end
end
