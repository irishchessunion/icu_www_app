class IncreaseSizeEventsUrl < ActiveRecord::Migration[7.0]
  def change
    change_column :events, :url, :string, limit: 255
  end
end
