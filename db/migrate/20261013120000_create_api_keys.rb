# Keys for third parties who use the API (see Api::BaseController). Only a digest of each key is stored.
class CreateApiKeys < ActiveRecord::Migration[8.1]
  def change
    create_table :api_keys do |t|
      t.string  :name, limit: 100, null: false
      t.string  :key_digest, limit: 64, null: false
      t.string  :key_prefix, limit: 8, null: false
      t.string  :permissions
      t.boolean :active, default: true

      t.timestamps
    end

    add_index :api_keys, :key_digest, unique: true
    add_index :api_keys, :name, unique: true
  end
end
