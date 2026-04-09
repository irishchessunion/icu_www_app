class AddFideFieldsToPlayers < ActiveRecord::Migration[6.0]
  def change
    add_column :players, :fide_id, :integer
    add_column :players, :fide_rating, :integer, limit: 2
    add_column :players, :fide_rapid_rating, :integer, limit: 2
    add_column :players, :fide_blitz_rating, :integer, limit: 2
  end
end
