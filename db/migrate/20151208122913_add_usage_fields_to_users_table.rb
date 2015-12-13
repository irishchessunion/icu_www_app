class AddUsageFieldsToUsersTable < ActiveRecord::Migration
  def change
    add_column :users, :last_used_at, :datetime
    add_index :users, :last_used_at
    add_index :logins, [:created_at, :user_id]
    add_index :logins, :created_at
  end
end
