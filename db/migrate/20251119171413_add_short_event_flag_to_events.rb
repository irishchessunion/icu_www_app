class AddShortEventFlagToEvents < ActiveRecord::Migration[7.0]
  def change
    add_column :events, :short_event, :boolean, default: true
  end
end
