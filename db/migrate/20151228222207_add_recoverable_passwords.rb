class AddRecoverablePasswords < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :reset_password_token, :string
    add_column :users, :reset_password_sent_at, :timestamp
  end
end
