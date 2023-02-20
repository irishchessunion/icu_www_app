class AddPrivacyToPlayers < ActiveRecord::Migration[7.0]
  def change
    add_column :players, :privacy, :string
  end
end
