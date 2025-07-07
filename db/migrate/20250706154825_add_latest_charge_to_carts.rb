class AddLatestChargeToCarts < ActiveRecord::Migration[7.0]
  def change
    add_column :carts, :latest_charge, :string, limit: 50
  end
end
