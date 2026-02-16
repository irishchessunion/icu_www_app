class CreateEventUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :event_users do |t|
      t.integer :event_id, null: false
      t.integer :user_id, null: false
      t.string :role, null: false, default: "full_access"

      t.timestamps
    end

    add_index :event_users, [:event_id, :user_id], unique: true
    add_index :event_users, :event_id
    add_index :event_users, :user_id
  end
end
