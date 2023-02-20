class AddUsageFieldsToUsersTable < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :last_used_at, :datetime
    add_index :users, :last_used_at
    add_index :logins, [:created_at, :user_id]
    add_index :logins, :created_at
  end
end
