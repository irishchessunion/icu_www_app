class AddEircodeToClubs < ActiveRecord::Migration[7.0]
  def change
    add_column :clubs, :eircode, :string
  end
end
