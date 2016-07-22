class IncreaseSizeEventsUrl < ActiveRecord::Migration
  def change
    change_column :events, :url, :string, limit: 255
  end
end
