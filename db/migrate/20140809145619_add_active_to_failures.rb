class AddActiveToFailures < ActiveRecord::Migration[7.0]
  def change
    add_column :failures, :active, :boolean, default: true
  end
end
