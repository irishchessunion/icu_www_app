class AddJuniorOptionsToClubsTable < ActiveRecord::Migration[7.0]
  def change
    add_column :clubs, :junior_only, :boolean, default: false
    add_column :clubs, :has_junior_section, :boolean, default: false
  end
end
