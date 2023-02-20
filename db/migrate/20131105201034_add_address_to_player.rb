class AddAddressToPlayer < ActiveRecord::Migration[7.0]
  def change
    add_column :players, :address, :string
  end
end
