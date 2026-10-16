# Existing event and club notes are Markdown (events) or plain text (clubs), so they default to true and are
# converted to HTML the next time they're saved from the WYSIWYG editor, as with news and articles.
class AddMarkdownToEventsAndClubs < ActiveRecord::Migration[8.1]
  def change
    add_column :events, :markdown, :boolean, default: true
    add_column :clubs, :markdown, :boolean, default: true
  end
end
