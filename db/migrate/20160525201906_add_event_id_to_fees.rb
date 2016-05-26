class AddEventIdToFees < ActiveRecord::Migration
  def change
    add_reference :fees, :event, index: true, foreign_key: true
  end
end
