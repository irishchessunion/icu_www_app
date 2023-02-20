class AddNoteToPlayers < ActiveRecord::Migration[7.0]
  def change
    add_column :players, :note, :text
  end
end
