class AddMarkdownToNews < ActiveRecord::Migration[8.0]
  def change
    add_column :news, :markdown, :boolean, default: true
  end
end
