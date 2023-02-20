class AddClubToPlayer < ActiveRecord::Migration[7.0]
  def change
    add_column :players, :club_id, :integer
  end
end
