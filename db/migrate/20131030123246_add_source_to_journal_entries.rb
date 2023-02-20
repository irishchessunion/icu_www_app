class AddSourceToJournalEntries < ActiveRecord::Migration[7.0]
  def change
    add_column :journal_entries, :source, :string, limit: 8, default: "www2"
  end
end
