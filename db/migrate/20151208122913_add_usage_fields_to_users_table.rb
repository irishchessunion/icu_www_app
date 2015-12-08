class AddUsageFieldsToUsersTable < ActiveRecord::Migration
  def change
    add_column :users, :last_used_at, :datetime
  end
end
