class AddTimeControlsToEvents < ActiveRecord::Migration[7.0]
  def change
    add_column :events, :time_controls, :json
  end
end
