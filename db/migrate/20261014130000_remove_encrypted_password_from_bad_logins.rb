class RemoveEncryptedPasswordFromBadLogins < ActiveRecord::Migration[8.1]
  def change
    remove_column :bad_logins, :encrypted_password, :string, limit: 32
  end
end
