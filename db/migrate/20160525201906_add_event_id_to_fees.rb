class AddEventIdToFees < ActiveRecord::Migration[7.0][7.0]
  def change
    add_reference :fees, :event, index: true, foreign_key: true
  end
end
