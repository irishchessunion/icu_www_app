# The Irish translations now live in config/locales/ga.yml (issue #303).
class DropTranslations < ActiveRecord::Migration[8.1]
  def up
    # Their journal pages would fail to load the Translation class, which no longer exists
    execute "DELETE FROM journal_entries WHERE journalable_type = 'Translation'"
    drop_table :translations
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
