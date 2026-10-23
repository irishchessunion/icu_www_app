class AddOverseasToFees < ActiveRecord::Migration[8.1]
  def change
    add_column :fees, :overseas, :boolean, default: false, null: false
  end
end
