# Details that third parties who list our events ask for (see app/views/api/v1/events/index.json.jbuilder).
class AddApiFieldsToEvents < ActiveRecord::Migration[8.1]
  def change
    add_column :events, :tournament_type, :string, limit: 20, default: "swiss", null: false
    add_column :events, :time_control_details, :string, limit: 50
    add_column :events, :icu_rated, :boolean, default: true, null: false
    add_column :events, :max_participants, :integer
  end
end
