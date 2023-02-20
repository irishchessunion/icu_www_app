class CreateRefunds < ActiveRecord::Migration[7.0]
  def change
    create_table :refunds do |t|
      t.integer  :cart_id, :user_id
      t.string   :error
      t.decimal  :amount, precision: 9, scale: 2

      t.datetime :created_at
    end
  end
end
