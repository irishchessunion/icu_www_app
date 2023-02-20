class AddReportingFieldsToEventsTable < ActiveRecord::Migration[7.0]
  def change
    add_column :events, :pairings_url, :string
    add_column :events, :results_url, :string
    add_column :events, :live_games_url, :string
    add_column :events, :report_url, :string
  end
end
