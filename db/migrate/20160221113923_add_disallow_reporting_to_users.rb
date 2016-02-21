class AddDisallowReportingToUsers < ActiveRecord::Migration
  def up
    add_column :users, :disallow_reporting, :boolean
    User.where(player_id: User::ASSHOLE_PLAYER_IDS).update_all(disallow_reporting: true)
  end

  def down
    remove_column :users, :disallow_reporting
  end
end
