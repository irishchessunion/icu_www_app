class AddEnabledToRelays < ActiveRecord::Migration[7.0]
  def change
    add_column :relays, :enabled, :boolean, default: true
  end
end
