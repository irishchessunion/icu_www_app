class AddInLinkToGames < ActiveRecord::Migration[7.0]
  def change
    add_column :games, :in_link, :boolean
  end
end
