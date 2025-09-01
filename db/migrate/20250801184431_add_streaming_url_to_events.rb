class AddStreamingUrlToEvents < ActiveRecord::Migration[7.0]
  def change
    add_column :events, :streaming_url, :string
    add_column :events, :live_games_url2, :string
  end
end
