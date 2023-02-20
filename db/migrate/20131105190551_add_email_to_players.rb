class AddEmailToPlayers < ActiveRecord::Migration[7.0]
  def change
    add_column :players, :email, :string, limit: 50
  end
end
