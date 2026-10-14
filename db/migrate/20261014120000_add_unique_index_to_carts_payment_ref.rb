class AddUniqueIndexToCartsPaymentRef < ActiveRecord::Migration[8.1]
  def change
    add_index :carts, :payment_ref, unique: true
  end
end
