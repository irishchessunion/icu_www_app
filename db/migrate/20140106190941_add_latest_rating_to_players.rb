class AddLatestRatingToPlayers < ActiveRecord::Migration[7.0]
  def change
    add_column :players, :latest_rating, :integer, limit: 2
  end
end
