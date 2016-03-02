class AddInLinkToGames < ActiveRecord::Migration
  def change
    add_column :games, :in_link, :boolean
  end
end
