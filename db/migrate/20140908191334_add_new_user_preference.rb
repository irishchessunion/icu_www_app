class AddNewUserPreference < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :hide_header, :boolean, default: false
  end
end
