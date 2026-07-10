class AddNotesAndDescriptionToClubs < ActiveRecord::Migration[7.1]
  def change
    add_column :clubs, :description, :string
    add_column :clubs, :notes, :text, limit: 65535
  end
end
