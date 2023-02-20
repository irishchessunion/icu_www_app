class AddFedToPlayer < ActiveRecord::Migration[7.0]
  def change
    add_column :players, :fed, :string, limit: 3
  end
end
